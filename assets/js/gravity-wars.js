/*
 * Gravity Wars: a JavaScript port of gravity_wars.pl (PERL/Tk version 2.0, 2002).
 * Same physics, random setups, ship drawings and controls as the PERL version,
 * but the torpedo is animated as it flies.
 *
 * Copyright (C) 2002 Sohrab Ismail-Beigi
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.  See COPYING.txt for details.
 */
(function () {
  "use strict";

  // All units of distance are in pixels, as in the PERL version.
  const SW = 640, SH = 480;                                // battlefield size
  const G = 0.1;
  const SHIP_RADIUS = 25;                                  // contains a ship completely
  const CRITICAL_DIST = 2 * Math.sqrt(SW * SW + SH * SH);  // beyond this, check for escape
  const N_STARS = 1000;
  const MIN_SPEED = 0, MAX_SPEED = 10;
  const BLACK_HOLE_PROB = 0.05;

  // Animation (new in this version): how fast simulated time runs on screen,
  // fast-forwarding while the torpedo is off screen, and when to give up on a
  // torpedo stuck in orbit (the PERL version would compute forever).
  const SIM_TIME_PER_MS = 0.07;
  const OFFSCREEN_SPEEDUP = 25;
  const MAX_STEPS_PER_FRAME = 400;
  const MAX_OFFSCREEN_STEPS_PER_FRAME = 5000;
  const MAX_FLIGHT_MS = 40000;

  // Tk's named colors.
  const GREY = "#bebebe", DARKGREY = "#a9a9a9", RED = "#ff0000";
  const PLANET_COLORS = ["#ff0000", "#00ff00", "#0000ff"];   // density 1, 2, 3
  const SHIP_NAMES = ["Enterprise", "Klingon ship"];

  const field = document.getElementById("gw-canvas");
  if (!field) return;
  const ctx = setupCanvas(field);
  const overlay = setupCanvas(document.getElementById("gw-overlay"));
  const hitCtx = document.createElement("canvas").getContext("2d");
  hitCtx.lineWidth = 1;

  const ui = {
    form: document.getElementById("gw-controls"),
    player: document.getElementById("gw-player"),
    ship: document.getElementById("gw-ship"),
    angle: document.getElementById("gw-angle"),
    speed: document.getElementById("gw-speed"),
    fire: document.getElementById("gw-fire"),
    redraw: document.getElementById("gw-redraw"),
    newGame: document.getElementById("gw-new"),
    status: document.getElementById("gw-status"),
    gameOver: document.getElementById("gw-gameover"),
    gameOverText: document.getElementById("gw-gameover-text"),
    ok: document.getElementById("gw-ok"),
  };

  // Describes the current setup.
  let planets = [];  // {x, y, r, GM, color}; r = 0 for a black hole
  let totGM = 0;     // total sum of G*M in the system
  let ships = [];    // [Enterprise (player 1), Klingon (player 2)]: {x, y, shapes}

  // Firing angle and speed remembered for each player, and whose turn it is.
  let angles = [0, 0], speeds = [1, 1];
  let player = 1;
  let flight = null; // the torpedo in flight, if any

  function setupCanvas(canvas) {
    const dpr = window.devicePixelRatio || 1;
    canvas.width = SW * dpr;
    canvas.height = SH * dpr;
    const c = canvas.getContext("2d");
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
    return c;
  }

  function rand(n) { return Math.random() * n; }

  // Is the circle with center (x, y) and radius r completely on the screen?
  function inBounds(x, y, r) {
    return !(x - r < 0 || x + r > SW || y - r < 0 || y + r > SH);
  }

  // Creates a new random setup: between 1 and 9 planets, some of which may be
  // black holes, and the two ships, all on screen and not colliding.  A very
  // crowded setup can leave no room at all, so then we simply start over.
  function makeRandomSetup() {
    while (!tryRandomSetup()) { /* try again */ }
  }

  function tryRandomSetup() {
    const np = Math.floor(rand(9)) + 1;
    planets = [];
    totGM = 0;
    for (let i = 0; i < np; i++) {
      let ok = false;
      for (let tries = 0; !ok; tries++) {
        if (tries > 10000) return false;
        // pick a random place, radius and density (1, 2 or 3) for the planet
        const x = Math.floor(rand(SW)), y = Math.floor(rand(SH));
        const d = Math.floor(rand(3)) + 1;
        let r = 0, GM;
        if (Math.random() > BLACK_HOLE_PROB) {
          r = Math.floor(rand(70)) + 20;
          GM = G * Math.PI * r * r * d;
        } else {                        // 5% chance of being a black hole
          GM = G * Math.PI * 30.0 * 30.0;
        }
        if (!inBounds(x, y, r)) continue;
        ok = planets.every(p => Math.hypot(x - p.x, y - p.y) > r + p.r);
        if (ok) {
          planets.push({ x, y, r, GM, color: PLANET_COLORS[d - 1] });
          totGM += GM;
        }
      }
    }

    // Place ships: random positions not colliding with a planet or other ship.
    ships = [];
    for (let i = 0; i < 2; i++) {
      let x, y, ok = false;
      for (let tries = 0; !ok; tries++) {
        if (tries > 10000) return false;
        if (i === 0) {
          x = Math.floor(rand(SW));
          y = Math.floor(rand(SH));
        } else {                        // second ship goes in the opposite quadrant
          x = Math.floor(rand(SW / 2)) + (ships[0].x < SW / 2 ? SW / 2 : 0);
          y = Math.floor(rand(SH / 2)) + (ships[0].y < SH / 2 ? SH / 2 : 0);
        }
        if (!inBounds(x, y, SHIP_RADIUS)) continue;
        ok = planets.every(p => Math.hypot(x - p.x, y - p.y) > SHIP_RADIUS + p.r + 10) &&
             ships.every(s => Math.hypot(x - s.x, y - s.y) > 2 * SHIP_RADIUS);
      }
      const shapes = (i === 0 ? enterpriseShapes : klingonShapes)(x, y).map(toPath);
      ships.push({ x, y, shapes });
    }
    return true;
  }

  // Ship drawings, transcribed from draw_enterprise and draw_klingon.
  // Coordinates are Tk-style: ovals and rectangles by opposite corners.
  function enterpriseShapes(x, y) {
    x += 14;
    return [
      ["oval", GREY, [x - 9, y - 9, x + 9, y + 9]],
      ["rect", GREY, [x - 23, y - 2, x, y + 2]],
      ["poly", GREY, [x - 18, y - 2, x - 21, y - 10, x - 34, y - 10, x - 34, y - 13,
                      x - 10, y - 13, x - 10, y - 10, x - 17, y - 10, x - 14, y - 2]],
      ["poly", GREY, [x - 18, y + 2, x - 21, y + 10, x - 34, y + 10, x - 34, y + 13,
                      x - 10, y + 13, x - 10, y + 10, x - 17, y + 10, x - 14, y + 2]],
      ["oval", RED, [x - 2, y - 2, x + 2, y + 2]],
      ["rect", RED, [x - 10, y - 13, x - 9, y - 10]],
      ["rect", RED, [x - 10, y + 13, x - 9, y + 10]],
    ];
  }

  function klingonShapes(x, y) {
    x -= 23;
    const shapes = [
      ["poly", GREY, [x, y, x + 5, y - 6, x + 10, y - 2, x + 20, y - 2, x + 25, y - 15,
                      x + 40, y - 15, x + 34, y, x + 40, y + 15, x + 25, y + 15,
                      x + 20, y + 2, x + 10, y + 2, x + 5, y + 6]],
      ["poly", RED, [x + 26, y, x + 30, y - 11, x + 33, y - 11, x + 30, y,
                     x + 33, y + 11, x + 30, y + 11]],
    ];
    x += 5;
    shapes.push(["oval", RED, [x - 1, y - 1, x + 1, y + 1]]);
    return shapes;
  }

  function toPath([kind, color, c]) {
    const path = new Path2D();
    if (kind === "oval") {
      path.ellipse((c[0] + c[2]) / 2, (c[1] + c[3]) / 2,
                   Math.abs(c[2] - c[0]) / 2, Math.abs(c[3] - c[1]) / 2, 0, 0, 2 * Math.PI);
    } else if (kind === "rect") {
      path.rect(Math.min(c[0], c[2]), Math.min(c[1], c[3]),
                Math.abs(c[2] - c[0]), Math.abs(c[3] - c[1]));
    } else {
      path.moveTo(c[0], c[1]);
      for (let i = 2; i < c.length; i += 2) path.lineTo(c[i], c[i + 1]);
      path.closePath();
    }
    return { path, color };
  }

  // Clears the battlefield and redraws the current setup.  The background
  // stars are random, as in the PERL version.
  function redrawSetup() {
    ctx.fillStyle = "#000";
    ctx.fillRect(0, 0, SW, SH);
    ctx.fillStyle = DARKGREY;
    for (let i = 0; i < N_STARS; i++) {
      ctx.fillRect(Math.floor(rand(SW)), Math.floor(rand(SH)), 1, 1);
    }
    for (const p of planets) {
      if (p.r === 0) continue;          // black holes are invisible
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, 2 * Math.PI);
      ctx.fillStyle = p.color;
      ctx.fill();
    }
    for (const ship of ships) {
      for (const { path, color } of ship.shapes) {
        ctx.fillStyle = ctx.strokeStyle = color;
        ctx.lineWidth = 1;
        ctx.fill(path);
        ctx.stroke(path);
      }
    }
    overlay.clearRect(0, 0, SW, SH);
  }

  // Reset everything and start a new game.
  function newGame() {
    flight = null;
    player = 1;
    angles = [0, 0];
    speeds = [1, 1];
    makeRandomSetup();
    redrawSetup();
    ui.gameOver.hidden = true;
    setStatus("");
    updateControls();
  }

  // One step of the torpedo's flight, exactly as in the PERL version: move,
  // update the velocity from the planets' gravity, then pick the next time
  // step so the torpedo moves two pixels per step.
  function stepTorpedo(f) {
    f.x += f.vx * f.dt;
    f.y += f.vy * f.dt;
    let ax = 0, ay = 0;
    for (const p of planets) {
      const dx = f.x - p.x, dy = f.y - p.y;
      const dr = Math.sqrt(dx * dx + dy * dy);
      // black holes are softened very close in
      const denom = p.r > 0 ? dr ** 3 : dr ** 3 + 1 / dr ** 4;
      ax -= p.GM * dx / denom;
      ay -= p.GM * dy / denom;
    }
    f.vx += ax * f.dt;
    f.vy += ay * f.dt;
    f.dt = 2.0 / Math.sqrt(f.vx * f.vx + f.vy * f.vy);
  }

  // Did the segment of the torpedo's path hit a planet or a ship?  Returns
  // "planet", the number of the player whose ship was hit, or null.
  function hitTest(x0, y0, x1, y1) {
    for (const p of planets) {
      if (p.r > 0 && segmentDistance(p.x, p.y, x0, y0, x1, y1) <= p.r + 0.5) return "planet";
    }
    for (let i = 0; i < 2; i++) {
      for (const { path } of ships[i].shapes) {
        for (const t of [0, 0.5, 1]) {
          const x = x0 + t * (x1 - x0), y = y0 + t * (y1 - y0);
          if (hitCtx.isPointInPath(path, x, y) || hitCtx.isPointInStroke(path, x, y)) return i + 1;
        }
      }
    }
    return null;
  }

  function segmentDistance(px, py, x0, y0, x1, y1) {
    const dx = x1 - x0, dy = y1 - y0, len2 = dx * dx + dy * dy;
    const t = len2 > 0 ? Math.max(0, Math.min(1, ((px - x0) * dx + (py - y0) * dy) / len2)) : 0;
    return Math.hypot(px - (x0 + t * dx), py - (y0 + t * dy));
  }

  // The fire button was pressed: launch the torpedo and animate its flight.
  function fire() {
    if (flight || !ui.gameOver.hidden) return;
    const a = parseFloat(ui.angle.value), s = parseFloat(ui.speed.value);
    if (!(a >= 0 && a <= 360)) {
      setStatus("Angle must be between 0 and 360. Try again.", true);
      return;
    }
    if (!(s >= MIN_SPEED && s <= MAX_SPEED)) {
      setStatus(`Speed must be between ${MIN_SPEED} and ${MAX_SPEED}. Try again.`, true);
      return;
    }
    const i = player - 1;
    angles[i] = a;
    speeds[i] = s;
    const rad = a * Math.PI / 180.0;
    const now = performance.now();
    flight = {
      x: ships[i].x + SHIP_RADIUS * Math.cos(rad),
      y: ships[i].y - SHIP_RADIUS * Math.sin(rad),
      vx: s * Math.cos(rad),
      vy: -s * Math.sin(rad),
      dt: 0.10,
      onScreen: true,
      start: now,
      lastFrame: now,
    };
    setStatus("");
    updateControls();
    requestAnimationFrame(animate);
  }

  function animate(now) {
    const f = flight;
    if (!f) return;
    const elapsed = Math.max(0, Math.min(now - f.lastFrame, 50));
    f.lastFrame = now;
    let budget = elapsed * SIM_TIME_PER_MS * (f.onScreen ? 1 : OFFSCREEN_SPEEDUP);
    const maxSteps = f.onScreen ? MAX_STEPS_PER_FRAME : MAX_OFFSCREEN_STEPS_PER_FRAME;

    ctx.strokeStyle = "#fff";
    ctx.lineWidth = 1;
    for (let n = 0; budget > 0 && n < maxSteps; n++) {
      const lastx = f.x, lasty = f.y;
      budget -= f.dt;
      stepTorpedo(f);
      f.onScreen = inBounds(f.x, f.y, 0);
      if (f.onScreen) {
        // draw the segment of the torpedo's path and see what it hit
        ctx.beginPath();
        ctx.moveTo(lastx, lasty);
        ctx.lineTo(f.x, f.y);
        ctx.stroke();
        const hit = hitTest(lastx, lasty, f.x, f.y);
        if (hit === "planet") return endTurn("");
        if (hit) return gameOver(hit === 1 ? 2 : 1);
      } else {
        // far enough away: has the torpedo reached escape velocity?
        const dx = f.x - SW / 2, dy = f.y - SH / 2;
        const dr = Math.sqrt(dx * dx + dy * dy);
        if (dr >= CRITICAL_DIST) {
          const vc = (f.vx * dx + f.vy * dy) / dr;
          if (0.5 * vc * vc >= totGM / dr) {
            return endTurn(`Player ${player}: your photon torpedo left the planetary system.`);
          }
        }
      }
    }
    if (now - f.start > MAX_FLIGHT_MS) {
      return endTurn(`Player ${player}: your photon torpedo is stuck in orbit.`);
    }

    // the torpedo itself, drawn on the overlay so it can move
    overlay.clearRect(0, 0, SW, SH);
    if (f.onScreen) {
      overlay.fillStyle = "#fff";
      overlay.beginPath();
      overlay.arc(f.x, f.y, 2.5, 0, 2 * Math.PI);
      overlay.fill();
      setStatus("");
    } else {
      setStatus("The torpedo is off screen…");
    }
    requestAnimationFrame(animate);
  }

  // No winner, so switch players for the next player's turn.
  function endTurn(message) {
    flight = null;
    overlay.clearRect(0, 0, SW, SH);
    player = player === 1 ? 2 : 1;
    setStatus(message);
    updateControls();
  }

  function gameOver(winner) {
    const { x, y } = flight;
    flight = null;
    overlay.clearRect(0, 0, SW, SH);
    // "explosion" dots around the loser's ship, centered where the torpedo struck
    ctx.fillStyle = "#ffff00";
    for (let i = 0; i < 800; i++) {
      const a = rand(2 * Math.PI), r = rand(30);
      ctx.fillRect(x + r * Math.cos(a), y + r * Math.sin(a), 1, 1);
    }
    ui.gameOverText.textContent = `Game over: player ${winner} wins!`;
    ui.gameOver.hidden = false;
    setStatus("");
    updateControls();
    ui.ok.focus();
  }

  function setStatus(message, isError) {
    if (ui.status.textContent !== message) ui.status.textContent = message;
    ui.status.classList.toggle("error", !!isError);
  }

  // Show whose turn it is, with that player's last angle and speed.
  function updateControls() {
    const busy = !!flight || !ui.gameOver.hidden;
    ui.player.textContent = player;
    ui.ship.textContent = `(${SHIP_NAMES[player - 1]})`;
    if (!flight) {
      ui.angle.value = angles[player - 1];
      ui.speed.value = speeds[player - 1];
    }
    ui.fire.disabled = busy;
    ui.redraw.disabled = busy;
  }

  ui.form.addEventListener("submit", e => { e.preventDefault(); fire(); });
  ui.redraw.addEventListener("click", () => { if (!flight) redrawSetup(); });
  ui.newGame.addEventListener("click", newGame);
  ui.ok.addEventListener("click", newGame);

  newGame();

  // For testing from the browser console.
  window.gravityWars = {
    stepTorpedo,
    setPlanets(list) {
      planets = list.map(p => Object.assign({ color: PLANET_COLORS[0] }, p));
      totGM = planets.reduce((sum, p) => sum + p.GM, 0);
    },
    state: () => ({ planets, ships: ships.map(({ x, y }) => ({ x, y })), player, flight }),
  };
})();
