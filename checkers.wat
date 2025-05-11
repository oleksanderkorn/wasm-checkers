(module
  ;; Define module events
  (import "events" "piececrowned" (func $notify_piececrowned (param $pieceX i32) (param $pieceY i32)))
  (import "events" "piecemoved" (func $notify_piecemoved (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32)))

  (memory $mem 1)
  ;; Global variables
  (global $WHITE i32 (i32.const 2))
  (global $BLACK i32 (i32.const 1))
  (global $CROWN i32 (i32.const 4))
  (global $currentTurn (mut i32) (i32.const 0))

  (func $indexForPosition (param $x i32) (param $y i32) (result i32)
    (i32.add
      (i32.mul
        (i32.const 8)
        (local.get $y)
      )
      (local.get $x)
    )
  )
  ;; Offset = (x + y * 8) * 4
  (func $offsetForPosition (param $x i32) (param $y i32) (result i32)
    (i32.mul
      (call $indexForPosition (local.get $x) (local.get $y))
      (i32.const 4)
    )
  )
  ;; Determine if the piece has been crowned
  (func $isCrowned (param $piece i32) (result i32)
    (i32.eq 
      (i32.and (local.get $piece) (global.get $CROWN))
      (global.get $CROWN)
    )
  )
  ;; Determine if the piece is white
  (func $isWhite (param $piece i32) (result i32)
    (i32.eq 
      (i32.and (local.get $piece) (global.get $WHITE))
      (global.get $WHITE)
    )
  )
  ;; Determine if the piece is black
  (func $isBlack (param $piece i32) (result i32)
    (i32.eq 
      (i32.and (local.get $piece) (global.get $BLACK))
      (global.get $BLACK)
    )
  )
  ;; Add a crown to a given piece (no mutation)
  (func $withCrown (param $piece i32) (result i32)
    (i32.or (local.get $piece) (global.get $CROWN))
  )
  ;; Removes a crown from a given piece (no mutation)
  (func $withoutCrown (param $piece i32) (result i32)
    (i32.and (local.get $piece) (i32.const 3))
  )
  ;; Sets a piece on the board
  (func $setPiece (param $x i32) (param $y i32) (param $piece i32)
    (i32.store
      (call $offsetForPosition
        (local.get $x)
        (local.get $y)
      )
      (local.get $piece)
    )
  )
  ;; Gets a piece from the board. Out of range causes a trap
  (func $getPiece (param $x i32) (param $y i32) (result i32)
    (if (result i32)
      (block (result i32)
        (i32.and
          (call $inRange
            (i32.const 0)
            (i32.const 7)
            (local.get $x)
          )
          (call $inRange
            (i32.const 0)
            (i32.const 7)
            (local.get $y)
          )
        )
      )
      (then
        (i32.load
          (call $offsetForPosition
            (local.get $x)
            (local.get $y)
          )
        )
      )
      (else
        (unreachable)
      )
    )
  )
  ;; Detect if values are withing range (inclusive low and high)
  (func $inRange (param $low i32) (param $high i32) (param $value i32) (result i32)
    (i32.and
      (i32.ge_s (local.get $value) (local.get $low))
      (i32.le_s (local.get $value) (local.get $high))
    )
  )
  ;; Gets the current turn owner (black or white)
  (func $getTurnOwner (result i32)
    (global.get $currentTurn)
  )
  ;; At the end of the turn, swith turn owner to the other player
  (func $toggleTurnOwner
    (if (i32.eq (call $getTurnOwner) (i32.const 1))
      (then (call $setTurnOwner (i32.const 0)))
      (else (call $setTurnOwner (i32.const 1)))
    ) 
  )
  ;; Sets turn owner
  (func $setTurnOwner (param $value i32)
    (global.set $currentTurn (local.get $value))
  )
  ;; Determine if it's a player's turn
  (func $isPlayerTurn (param $player i32) (result i32)
    (i32.gt_s
      (i32.and (local.get $player) (call $getTurnOwner))
      (i32.const 0)
    )
  )
  ;; Should this piece get crowned?
  ;; We crown black pieces in row 0, white pieces in row 7
  (func $shouldCrown (param $pieceY i32) (param $piece i32) (result i32)
    (i32.or
      (i32.and
        (i32.eq
          (local.get $pieceY)
          (i32.const 0)
        )
        (call $isBlack (local.get $piece))
      )
      (i32.and
        (i32.eq
          (local.get $pieceY)
          (i32.const 7)
        )
        (call $isWhite (local.get $piece))
      )
    )
  )
  ;; Converts a piece into a crowned piece and invokes a host notifier
  (func $crownPiece (param $x i32) (param $y i32)
    (local $piece i32)
    (local.set $piece (call $getPiece (local.get $x) (local.get $y)))
    (call $setPiece (local.get $x) (local.get $y)
      (call $withCrown (local.get $piece)))
    (call $notify_piececrowned (local.get $x) (local.get $y))
  )
  (func $distance (param $x i32) (param $y i32) (result i32)
    (i32.sub (local.get $x) (local.get $y))
  )
  ;; Determine if a move is valid
  (func $isValidMove (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
    (local $player i32)
    (local $target i32)
    (local.set $player (call $getPiece (local.get $fromX) (local.get $fromY)))
    (local.set $target (call $getPiece (local.get $toX) (local.get $toY)))
    (if (result i32)
      (block (result i32)
        (i32.and
          (call $validJumpDistance (local.get $fromY) (local.get $toY))
          (i32.and
            (call $isPlayerTurn (local.get $player))
            ;; target must be unoccupied
            (i32.eq (local.get $target) (i32.const 0))
          )
        )
      )
      (then 
        (i32.const 1)
      )
      (else
        (i32.const 0)
      )
    )
  )
  ;; Ensure travel is 1 or 2 squares
  (func $validJumpDistance (param $from i32) (param $to i32) (result i32)
    (local $d i32)
    (local.set $d
      (if (result i32)
        (i32.gt_s (local.get $to) (local.get $from))
        (then (call $distance (local.get $to) (local.get $from)))
        (else (call $distance (local.get $from) (local.get $to)))
      )
    )
    (i32.le_u
      (local.get $d)
      (i32.const 2)
    )
  )
  ;; Exported move function to be called by the game host
  (func $move (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
    (if (result i32)
      (block (result i32)
        (call $isValidMove (local.get $fromX) (local.get $fromY) (local.get $toX) (local.get $toY))
      )
      (then 
        (call $do_move (local.get $fromX) (local.get $fromY) (local.get $toX) (local.get $toY))
      )
      (else (i32.const 0))
    )
  )
  ;; Internal move function, performs actual move post-validation of target. 
  ;; Currently not handled: 
  ;;  - removing opponent piece during a jump
  ;;  - detecting win condition
  (func $do_move (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
    (local $curpiece i32)
    (local.set $curpiece (call $getPiece (local.get $fromX) (local.get $fromY)))

    (call $toggleTurnOwner)
    (call $setPiece (local.get $toX) (local.get $toY) (local.get $curpiece))
    (call $setPiece (local.get $fromX) (local.get $fromY) (i32.const 0))
    (if (call $shouldCrown (local.get $toY) (local.get $curpiece))
      (then (call $crownPiece (local.get $toX) (local.get $toY))))
    (call $notify_piecemoved (local.get $fromX) (local.get $fromY) (local.get $toX) (local.get $toY)) 
    (i32.const 1)
  )
  ;; Manually place each piece on the board to initialize the game
  (func $initBoard
    ;; Place the white pieces at the top of the board
    (call $setPiece (i32.const 1) (i32.const 0) (i32.const 2))
    (call $setPiece (i32.const 3) (i32.const 0) (i32.const 2))
    (call $setPiece (i32.const 5) (i32.const 0) (i32.const 2))
    (call $setPiece (i32.const 7) (i32.const 0) (i32.const 2))
    ;; Place the black pieces at the top of the board
    (call $setPiece (i32.const 0) (i32.const 0) (i32.const 1))
    (call $setPiece (i32.const 2) (i32.const 0) (i32.const 1))
    (call $setPiece (i32.const 4) (i32.const 0) (i32.const 1))
    (call $setPiece (i32.const 6) (i32.const 0) (i32.const 1))

    ;; Place black pieces (1) on rows 0-2
    ;; Row 0 (black)
    (call $setPiece (i32.const 1) (i32.const 0) (i32.const 1))
    (call $setPiece (i32.const 3) (i32.const 0) (i32.const 1))
    (call $setPiece (i32.const 5) (i32.const 0) (i32.const 1))
    (call $setPiece (i32.const 7) (i32.const 0) (i32.const 1))

    ;; Row 1 (black)
    (call $setPiece (i32.const 0) (i32.const 1) (i32.const 1))
    (call $setPiece (i32.const 2) (i32.const 1) (i32.const 1))
    (call $setPiece (i32.const 4) (i32.const 1) (i32.const 1))
    (call $setPiece (i32.const 6) (i32.const 1) (i32.const 1))

    ;; Row 2 (black)
    (call $setPiece (i32.const 1) (i32.const 2) (i32.const 1))
    (call $setPiece (i32.const 3) (i32.const 2) (i32.const 1))
    (call $setPiece (i32.const 5) (i32.const 2) (i32.const 1))
    (call $setPiece (i32.const 7) (i32.const 2) (i32.const 1))

    ;; Rows 3 and 4 are empty - no need to explicitly set them to 0

    ;; Place white pieces (2) on rows 5-7
    ;; Row 5 (white)
    (call $setPiece (i32.const 0) (i32.const 5) (i32.const 2))
    (call $setPiece (i32.const 2) (i32.const 5) (i32.const 2))
    (call $setPiece (i32.const 4) (i32.const 5) (i32.const 2))
    (call $setPiece (i32.const 6) (i32.const 5) (i32.const 2))

    ;; Row 6 (white)
    (call $setPiece (i32.const 1) (i32.const 6) (i32.const 2))
    (call $setPiece (i32.const 3) (i32.const 6) (i32.const 2))
    (call $setPiece (i32.const 5) (i32.const 6) (i32.const 2))
    (call $setPiece (i32.const 7) (i32.const 6) (i32.const 2))

    ;; Row 7 (white)
    (call $setPiece (i32.const 0) (i32.const 7) (i32.const 2))
    (call $setPiece (i32.const 2) (i32.const 7) (i32.const 2))
    (call $setPiece (i32.const 4) (i32.const 7) (i32.const 2))
    (call $setPiece (i32.const 6) (i32.const 7) (i32.const 2))

    ;; Assign initial turn owner, black goes first
    (call $setTurnOwner (i32.const 1))
  )
 
  ;; Define module exports
  (export "getPiece" (func $getPiece))
  (export "isCrowned" (func $isCrowned))
  (export "initBoard" (func $initBoard))
  (export "getTurnOwner" (func $getTurnOwner))
  (export "move" (func $move))
  (export "memory" (memory $mem))
)
