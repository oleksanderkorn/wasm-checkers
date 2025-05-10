(module
  (memory $mem 1)
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
)
