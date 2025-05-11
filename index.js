(async () => {
  const response = await fetch('./checkers.wasm');
  const bytes = await response.arrayBuffer();
  const results = await WebAssembly.instantiate(bytes, {
    events: {
      piecemoved: (fX, fY, tX, tY) => {
        console.log(`Piece moved from (${fX}, ${fY}) to (${tX}, ${tY})`);
      },
      piececrowned: (pX, pY) => {
        console.log(`Piece crowned at (${pX}, ${pY})`);
      }
    }
  });

  const instance = results.instance;
  console.log("instance", instance);
  instance.exports.initBoard();

  console.debug("At start, turn owner is", instance.exports.getTurnOwner());
  console.log("move", instance.exports.move(0, 5, 0, 4)); // B
  console.log("move", instance.exports.move(1, 0, 1, 1)); // W
  console.log("move", instance.exports.move(0, 4, 0, 3)); // B
  console.log("move", instance.exports.move(1, 1, 1, 0)); // W
  console.log("move", instance.exports.move(0, 3, 0, 2)); // B
  console.log("move", instance.exports.move(1, 0, 1, 1)); // W
  console.log("move", instance.exports.move(0, 2, 0, 0)); // B - this should get a crown
  console.log("move", instance.exports.move(1, 1, 1, 0)); // W

  // B - move crowned piece out
  let res = instance.exports.move(0, 0, 0, 2);
  document.getElementById("container").innerText = res;
  console.debug("At end, turn owner is", instance.exports.getTurnOwner());
})();
