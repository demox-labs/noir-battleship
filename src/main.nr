fn main(x : Field, y : pub Field) {
    assert(x != y);
}

// SECTION: Verification Logic

// input x (u64): an input that corresponds to a u64 bitstring
// returns the number of "flipped" bits.
// E.g. 17870283321406128128, in binary 11111000 00000000 00000000 00000000 00000000 00000000 00000000 00000000,
// returns 5u64;
fn count_bits(x : u64) -> u64 {
    let shift1 = (x / 2) & 8608480567731124087;
    let shift2 = (x / 4) & 3689348814741910323;
    let shift3 = (x / 8) & 1229782938247303441;

    let sub1 = x - shift1;
    let sub2 = sub1 - shift2;
    let sub3 = sub2 - shift3;

    let shift4 = sub3 / 16;
    let unmasked_count = sub3 + shift4;
    let masked_count = unmasked_count & 1085102592571150095;
    let count = masked_count % 255;

    count
}

#[test]
fn test_count_bits() {
    let num_bits1: u64 = count_bits(1);
    let expected_bits1: u64 = 1;
    assert(num_bits1 == expected_bits1);

    let num_bits2: u64 = count_bits(2);
    let expected_bits2: u64 = 1;
    assert(num_bits2 == expected_bits2);

    let num_bits3: u64 = count_bits(3);
    let expected_bits3: u64 = 2;
    assert(num_bits3 == expected_bits3);

    let num_bits4: u64 = count_bits(18446744073709551615);
    let expected_bits4: u64 = 64;
    assert(num_bits4 == expected_bits4);

    let num_bits5: u64 = count_bits(17870283321406128128);
    let expected_bits5: u64 = 5;
    assert(num_bits5 == expected_bits5);
}


// input r0 (u64): the u64 representation of a ship's placement in an 8x8 grid.
// input r1 (u64): the u64 representation of a ship's bitstring, either horizontally or vertically.
// E.g. a ship of length 3's bit string horizontally would be: 000111 = 7u64. Vertically, the bit string would be:
// 10000000100000001 = 65793u64.
// returns boolean of whether all the flipped bits in r0 are "adjacent". Horizontally, this means all flipped bits are
// directly next to each other (111). Vertically, this means all flipped bits are separated by 7 unflipped bits
// (10000000100000001).
fn adjacency_check(placement : u64, ship : u64) -> bool {
    let remainder = placement / ship;
    let is_vertical = (remainder == 0);
    let r4 = if is_vertical { 3 } else { remainder };
    let r5 = r4 - 1;
    let r6 = r4 & r5;
    let r7 = r6 == 0;

    r7
}

#[test]
fn test_adjacency_check() {
    // 0000000000000000000000000000000000000000000000000000000000000111
    let are_adjacent1: bool = adjacency_check(7, 7);
    assert(are_adjacent1 == true);

    // 1000000010000000100000000000000000000000000000000000000000000000
    let are_adjacent2: bool = adjacency_check(9259541571362095104, 65793);
    assert(are_adjacent2 == true);

    // 1110000000000000000000000000000000000000000000000000000000000000
    let are_adjacent3: bool = adjacency_check(16140901064495857664, 7);
    assert(are_adjacent3 == true);
}

// input r0 (u64): the u64 representation of a ship's placement in an 8x8 grid.
// input r1 (u64): the u64 representation of a ship's bitstring horizontally
// returns boolean of whether adjacent flipped bits don't split a row of size 8.
// E.g. 111000000 has adjacent flipped bits but splits a row: 00000001 11000000
fn horizontal_check(r0 : u64, r1 : u64) -> bool {
    let r2 = r0 % 255;
    let r3 = r2 / r1;
    let r4 = r3 == 0;
    let r5 = if r4 { 3 } else { r3 };
    let r6 = r5 - 1;
    let r7 = r5 & r6;
    let r8 = r7 == 0;

    r8
}

#[test]
fn test_horizontal_check() {
    // 00000000 00000000 00000000 00000000 00000000 00000000 00000001 11000000
    let not_split1: bool = horizontal_check(448, 7);
    assert(not_split1 == false);

    // 00000000 00000000 00000000 00000000 00000000 00000000 00000000 11100000
    let not_split2: bool = horizontal_check(224, 7);
    assert(not_split2 == true);
}

// input r0 (u64): the u64 representation of a ship's placement in an 8x8 grid.
// input r1 (u64): the length of the placed ship
// input r2 (u64): the u64 equivalent of a ship's horizontal bitstring representation
// input r3 (u64): the u64 equivalent of a ship's vertical bitstring representation
// returns boolean whether the ship placement is valid or not
fn validate_ship_placement(r0 : u64, r1 : u64, r2 : u64, r3 : u64) -> bool {
    let r4 = count_bits(r0);
    assert(r4 == r1);

    let r5 = adjacency_check(r0, r2);
    let r6 = horizontal_check(r0, r2);
    let r7 = r5 & r6;
    let r8 = adjacency_check(r0, r3);
    let r9 = r7 | r8;

    r9
}

// input r0 (u64): the u64 representation of a carrier's placement in an 8x8 grid. Length = 5.
// input r1 (u64): the u64 representation of a battleship's placement in an 8x8 grid. Length = 4.
// input r2 (u64): the u64 representation of a cruiser's placement in an 8x8 grid. Length = 3.
// input r3 (u64): the u64 representation of a destroyer's placement in an 8x8 grid. Length = 2.
// returns the u64 representation of all the ships' placements in an 8x8 grid. This function will fail
// if any of the ship placements overlap each other.
fn create_board(r0 : u64, r1 : u64, r2 : u64, r3 : u64) -> u64 {
    let board = r0 | r1 | r2 | r3;
    let count = count_bits(board);
    assert(count == 14);

    board
}


// SECTION: Move

struct Move {
    owner: Field,
    incoming_fire_coordinate: u64,
    player_1: Field,
    player_2: Field,
    prev_hit_or_miss: u64,
}

// input r0 (move.record): the move record created by the opponent.
// input r1 (u64): the u64 representation of incoming_fire_coordinate, the bitstring fire coordinate
// to send to the opponent.
// input r2 (u64): the u64 representation of prev_hit_or_miss, this player's previous fire coordinate as a hit or miss.
// One flipped bit indicates a hit. No flipped bits indicates a miss.
// returns new move record owned by the opponent.
fn create_move(r0: Move, r1: u64, r2: u64) -> Move {
    let next_move = if r0.owner == r0.player_1 {
        Move {
            owner: r0.player_2,
            incoming_fire_coordinate: r1,
            player_1: r0.player_1,
            player_2: r0.player_2,
            prev_hit_or_miss: r2,
        }
    } else {
        Move {
            owner: r0.player_1,
            incoming_fire_coordinate: r1,
            player_1: r0.player_1,
            player_2: r0.player_2,
            prev_hit_or_miss: r2,
        }
    };

    next_move
}

// input player (address hash): the address of the first player
// input opponent (address hash): the address of the second player
// returns move record owned by the opponent. Note, this move record contains
// dummy fire coordinates and previous hit or miss.
fn start_game(player: Field, opponent: Field) -> Move {
    let move = Move {
        owner: opponent,
        incoming_fire_coordinate: 0,
        player_1: player,
        player_2: opponent,
        prev_hit_or_miss: 0,
    };

    move
}


// SECTION: Board 

// Battleship boards are represented by 8x8 squares.
// A u64 is all that is required to represent a hit or a miss on a single board.
// Starting from the top row, left to right, a hit is 1 and a miss is 0.
// A first move resulting in a hit in row 1, column 3 would be:
// 00100000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
// A second u64 is needed to represent which squares have been played, with 1s being played squares and 0s being
// unplayed squares.
struct BoardState {
    owner: Field,
    hits_and_misses: u64,
    played_tiles: u64,
    ships: u64,
    player_1: Field,
    player_2: Field,
    game_started: bool,
}

// input r0 (u64): u64 equivalent of the bitstring representation of a game board, 8x8.
// input r1 (address): the address of the opponent.
// input r2 (address): the address of the player
fn initialize_board(board: u64, player: Field, opponent: Field) -> BoardState {
    let board = BoardState {
        owner: player,
        hits_and_misses: 0,
        played_tiles: 0,
        ships: board,
        player_1: player,
        player_2: opponent,
        game_started: false,
    };

    board
}

// input r0 (board_state.record): the record of the board to start. A board can only be started once.
// returns a new board state record that has been started. Will fail if this board has been started before.
fn start_board(board: BoardState) -> BoardState {
    let board = BoardState {
        owner: board.owner,
        hits_and_misses: board.hits_and_misses,
        played_tiles: board.played_tiles,
        ships: board.ships,
        player_1: board.player_1,
        player_2: board.player_2,
        game_started: true,
    };

    board
}

// input r0 (board_state.record): the record of the board to update
// input r1 (u64): the u64 equivalent of a bitstring fire coordinate to send to the opponent.
// returns a new board state record that includes all the played tiles. Fails if r1 has been played before.
fn update_played_tiles(board: BoardState, move: u64) -> BoardState {
    let r2 = move - 1;
    let r3 = move & r2;
    assert(r3 == 0);

    let r4 = board.played_tiles & move;
    assert(r4 == 0);

    let board = BoardState {
        owner: board.owner,
        hits_and_misses: board.hits_and_misses,
        played_tiles: board.played_tiles | move,
        ships: board.ships,
        player_1: board.player_1,
        player_2: board.player_2,
        game_started: board.game_started,
    };

    board
}

// input r0 (board_state.record): the record of the board to update
// input r1 (u64): the u64 equivalent of a bitstring of whether this player's previous move was a hit or miss.
// returns a new board state record that includes all the hits and misses.
fn update_hits_and_misses(board: BoardState, move: u64) -> BoardState {
    let board = BoardState {
        owner: board.owner,
        hits_and_misses: board.hits_and_misses | move,
        played_tiles: board.played_tiles,
        ships: board.ships,
        player_1: board.player_1,
        player_2: board.player_2,
        game_started: board.game_started,
    };

    board
}
