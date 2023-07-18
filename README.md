## Testing

Run `nargo test` & all tests should pass

## Modeling the board and ships

To represent every space on a battleship board, from top left to bottom right, we can use each bit in a u64. For example, an empty board would be:
0u64 =
```
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0
```

Battleship is played with 4 different ship types -- a ship of length 5, length 4, length 3, and length 2. Some versions of battleship have an extra length 3 ship or another extra ship type, however, we will stick to the most basic version for this project. In order to be a valid ship placement, a ship must be placed vertically or horizontally (no diagonals). On a physical board, a ship cannot break across rows or intersect with another ship, but ships are allowed to touch one another.

Similar to how we represent a board with a u64 bitstring, we can represent a ship horizontally as a bitstring. We "flip" the bits to represent a ship:
| Length | Bitstring | u64 |
| ------ | --------- | --- |
| 5 | 11111 | 31u64|
| 4 | 1111  | 15u64|
| 3 | 111   | 7u64 |
| 2 | 11    | 3u64 |

We can also represent a ship vertically as a bitstring. To show this, we need 7 "unflipped" bits (zeroes) in between the flipped bits so that the bits are adjacent vertically.
| Length | Bitstring | u64 |
| --- | --- | --- |
| 5 | 1 00000001 00000001 00000001 00000001 | 4311810305u64 |
| 4 | 1 00000001 00000001 00000001          | 16843009u64 |
| 3 | 1 00000001 00000001                   | 65793u64 |
| 2 | 1 00000001                            | 257u64 |

With a board model and ship bitstring models, we can now place ships on a board.

<details><summary>Examples of valid board configurations:</summary>

17870284429256033024u64  
```
1 1 1 1 1 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 1  
0 0 0 0 0 0 0 1  
1 1 1 1 0 0 0 1  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 1 1  
0 0 0 0 0 0 0 0  
```

16383u64  
```
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 1 1 1 1 1 1  
1 1 1 1 1 1 1 1  
```

2157505700798988545u64  
```
0 0 0 1 1 1 0 1  
1 1 1 1 0 0 0 1  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 1  
0 0 0 0 0 0 0 1  
0 0 0 0 0 0 0 1  
0 0 0 0 0 0 0 1  
0 0 0 0 0 0 0 1  
```

</details>

<details><summary>Examples of invalid board configurations:</summary>

Ships overlapping the bottom ship:  
67503903u64  
```
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 1 0 0  
0 0 0 0 0 1 1 0  
0 0 0 0 0 1 1 1  
0 0 0 1 1 1 1 1  
```

Diagonal ships:  
9242549787790754436u64  
```
1 0 0 0 0 0 0 0  
0 1 0 0 0 1 0 0  
0 0 1 0 0 0 1 0  
0 0 0 1 0 0 0 0  
0 0 0 1 1 0 0 0  
0 0 1 0 0 0 0 1  
0 1 0 0 0 0 1 0  
1 0 0 0 0 1 0 0  
```

Ships splitting across rows and columns:  
1297811850814034450u64  
```
0 0 0 1 0 0 1 0  
0 0 0 0 0 0 1 0  
1 1 0 0 0 0 0 1  
0 0 0 0 0 0 0 0  
1 0 0 1 0 0 0 1  
0 0 0 1 0 0 0 0  
0 0 0 1 0 0 1 0  
0 0 0 1 0 0 1 0  
```
</details>

Given these rules, our strategy will be to validate each individaul ship bitstring placement on a board, and then, if all the ships are valid, compose all the positions onto a board and validate that the board with all ships are valid. If each individual ship's position is valid, then all the ships together should be valid unless any overlapping occurs.

## Validating a single ship at a time

To follow along with the code, all verification of ship bitstrings is done in the verify section of the code. We know a ship is valid if all these conditions are met:
If horizontal:
1. The correct number of bits is flipped (a ship of length 5 should not have 6 flipped bits)
2. All the bits are adjacent to each other.
3. The bits do not split a row.

If vertical:
1. The correct number of bits is flipped.
2. All the bits are adjacent to each other, vertically. This means that each flipped bit should be separated by exactly 7 unflipped bits.
3. The bits do not split a column.

If a ship is valid vertically or horizontally, then we know the ship is valid. We just need to check for the bit count, the adjacency of those bits, and make sure those bits do not split a row/column. However, we can't loop through the bit string to count bits, or to make sure those bits don't break across columns. We'll need to turn to special bitwise operations and hacks.

<details><summary>Bit Counting</summary>

See the "c_bitcount" function to follow along with the code. 50 years ago, MIT AI Laboratory published HAKMEM, which was a series of tricks and hacks to speed up processing for bitwise operations. https://w3.pppl.gov/~hammett/work/2009/AIM-239-ocr.pdf We turned to HAKMEM 169 for bitcounting inspiration, although we've tweaked our implementation to be (hopefully) easier to understand. Before diving into details, let's build some intuition.

Let a,b,c,d be either 0 or 1. Given a polynomial 8a + 4b + 2c + d, how do we find the summation of a + b + c + d?
If we subtract subsets of this polynomial, we'll be left with the summation.  
Step 1:  8a + 4b + 2c + d  
Step 2: -4a - 2b -  c  
Step 3: -2a -  b  
Step 4: - a  
Step 5: = a +  b +  c + d  
This polynomial is basically a bitwise representation of a number, so given a 4 bit number, e.g. 1011 or 13u64, we can follow these instructions to get the bit count. Step 2 is just subtracting the starting number but bit shifted to the right (equivalent to dividing by 2). Step 3 bit shifts the starting number to the right twice and is subtracted, and Step 4 bit shifts thrice and is subtracted. Put another way: Start with a 4-digit binary number A. A - (A >> 1) - (A >> 2) - (A >> 3) = B.  
Step 1:  1101 = 13u64  
Step 2: -0110 =  6u64  
Step 3: -0011 =  3u64  
Step 4: -0001 =  1u64  
Step 5: =0011 =  3u64  

To make this process work for any bit-length number, where the sum of the bits is left in groups of 4 bits, we'll need to use some bit-masking, so that the sum of one group of 4 does not interfere with the next group of 4.
With a larger starting number, like 1111 0001 0111 0110, we will need the following bit maskings:
```
For A >> 1, we'll use 0111 0111 0111 .... (in u64, this is 8608480567731124087u64)
For A >> 2, we'll use 0011 0011 0011 .... (in u64, this is 3689348814741910323u64)
For A >> 3, we'll use 0001 0001 0001 .... (in u64, this is 1229782938247303441u64)
```

For example, finding the sums of groups of 4 with a 16-bit number we'll call A to yield the bit sum number B:
```
A:    1111 0001 0111 0110  
A>>1: 0111 1000 1011 1011  
A>>2: 0011 1100 0101 1101  
A>>3: 0001 1110 0010 1110  

A>>1: 0111 1000 1011 1011  
    & 0111 0111 0111 0111:  
      0111 0000 0011 0011  

A>>2: 0011 1100 0101 1101  
    & 0011 0011 0011 0011:  
      0011 0000 0001 0001  

A>>3: 0001 1110 0010 1110  
    & 0001 0001 0001 0001:  
      0001 0000 0000 0000  

A - (A>>1 & 0111....) - (A>>2 & 0011....) - (A>>3 & 0001....):
B:    0100 0001 0011 0010  
      4    1    3    2
```

The next step is to combine the summation of each of those 4-bit groups into sums of 8-bit groups. To do this, we'll use another bit trick. We will shift this number B to the right by 4 (B >> 4), and add that back to B. Then, we'll apply a bit masking of 0000 1111 0000 1111 .... (in u64, this is 1085102592571150095u64) to yield the sums of bits in groups of 8, a number we'll call C.
```
B:    0100 0001 0011 0010  
B>>4: 0000 0100 0001 0011  
      0100 0101 0100 0101  
      4    5    4    5

apply the bit mask  
      0000 1111 0000 1111  

C:    0000 0101 0000 0101  
      0    5    0    5
```

At this point, we've gone from a bit sum in groups of 4 to bit sums in groups of 8. That's great, but ultimately we want the total sum of bits in the original binary number. The final bit trick is to modulo C by 255. This is 2^8 - 1. For a bit of intuition, consider the number 1 0000 0001. If we take 1 0000 0001 mod 256, we're left with 1. If we take 1 0000 0001 mod 255, we're left with 2. Modding by 255 gives us the amount of bits _beyond_ the first 255 numbers, as 255 is the largest number that can be represented with 8 bits.

A full summary of abbreviated steps to get the bit count, starting with a 64 bit integer A (closely following the bitcount function in the code):
let A = 64 unsigned bit integer
let B = A - (A>>1 & 8608480567731124087u64) - (A>>2 & 3689348814741910323u64) - (A>>3 & 1229782938247303441u64)
let C = (B - B>>4) & 1085102592571150095u64
bit count = C mod 255u64

</details>

<details><summary>Adjacency Check</summary>

Given a ship's placement on the board and its bitstring representation (horizontally or vertically), we can determine if the bits are adjacent. Follow the adjacency_check function in verify section. Given the ship of length 2, we know it's horizontal bitstring is 11 (3u64) and it's vertical bitstring is 100000001 (257u64). If on the board, the ship starts at the bottom right corner, its horizontal ship placement string would be:  
3u64  
```
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 1 1  
```

Vertical ship placement:  
257u64  
```
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 1  
0 0 0 0 0 0 0 1  
```

If we move the ship to the left one column:  
Horizontal 6u64  
```
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 1 1 0  
```

Vertical 514u64  
```
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 1 0  
0 0 0 0 0 0 1 0  
```

If we move the ship up one row:  
Horizontal 768u64  
```
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 1 1  
0 0 0 0 0 0 0 0  
```

Vertical 65792u64  
```
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 1  
0 0 0 0 0 0 0 1  
0 0 0 0 0 0 0 0  
```

We can make the observation that the original bitstring is always shifted by a power of 2 to get to a new valid position on the board. Therefore, if we take the ship placement bitstring and divide by the ship bitstring (either horizontal or vertical), as long as the remaining number is a power of 2 (2^0, 2^1, 2^2, 2^3...), we know the ship's bits are adjacent.

To ensure that the remaining number is a power of 2, we can use a bit trick. See the bit trick for ensuring a bitstring is a power of 2 section.

In the code, you'll notice one extra step. Dividing a ship placement bitstring by a ship bitstring representation could result in 0, and then subtracting by 1 will result in an underflow. In that case, we know the ship placement is not valid, so we can set a number which is gauranteed to not be a power of 2.
</details>

<details><summary>Splitting a row or column</summary>
Follow the horizontal_check function in verify section to follow the code. Assume all the bits are adjacent (see the adjacency check section). The column case is trivial. We can be certain that if a ship bitstring splits columns, the division of that ship placement bitstring by its ship bitstring representation will not yield a power of 2, and it would have failed the adjacency check.

The horizontal case must be checked because a split row bitstring could still contain a ship with adjacent bits. To make this check easier, we will condense the 64 bitstring into an 8 bitstring by taking it modulo 255. If we assume that a bitstring is not splitting a row, then taking the ship placement bitstring modulo 255 will yield an 8 bit valid bitstring. If the original ship placement bitstring is not valid, then we will have an invalid 8 bit bitstring. E.g.:  
```
1 1 1 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
```
mod 255 = 11100000 (valid)

```
0 0 0 0 0 0 0 1  
1 1 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
0 0 0 0 0 0 0 0  
```
mod 255 = 11000001 (invalid)

How do we know the 8 bit bitstring is valid or not? We can simply do an adjacency check, as before.

</details>

<details><summary>Ensuring a bitstring is a power of 2</summary>

Any power of 2 will have a single bit flipped. If we subtract 1 from that number, it will result in a complementary bitstring that, bitwise-anded with the original, will always result in 0.

E.g.
```
8:   1000
8-1: 0111
8&7: 0000 == 0

7:   0111
7-1: 0110
7&6: 0110 != 0
```

</details>

## Validating all ships together in a single board

Give individual valid ship position bitstrings, we can combine all these together into a single board using bitwise or operators. See the create_board function in verify section to follow the code. Once all ships are on the board, we can count the total number of bits, which should be 14 exactly for a ship of length 5, 4, 3, and 2.

## Ensure that players and boards cannot swap mid-game

Board states are represented with the board_state struct. Each board has a flag indicating whether a game has been started with the board. This flag is set when offering a battleship game to an opponent, or accepting a battleship game from an opponent. Move structs are created only in 3 ways:
1. Offering a battleship game creates a dummy move struct that sets the two players to the addresses set in the board state struct.
2. Accepting a battleship game consumes the first dummy move struct and checks that the move struct contains the same two players as the board of the player accepting the game. Then, a new dummy move struct is created and keeps the same two players.
2. A move struct must be consumed in order to play and create the next move struct. There's a check to ensure the players in the move struct matches the players in the board, and the players in the next move struct are automatically set.

The only way moves _not_ matching a board can be combined is if the players begin multiple games with each other. As long as one player is honest and only accepts a single game with a particular opponent, only one set of moves can be played on one board between them.

## Ensure that each player can only move once before the next player can move

A move struct must be consumed in order to create the next move struct. The owner of the move struct changes with each play. Player A must spend a move struct in order to create a move struct containing their fire coordinate, and that move struct will be owned by Player B. Player B must spend that move struct in order to create the next move struct, which will belong to Player A.

## Enforce constraints on valid moves, and force the player to give their opponent information about their opponent's previous move in order to continue playing

A valid move for a player is a fire coordinate that has only one flipped bit in a u64. We can make sure only one bit is flipped with the powers of 2 bit trick. That single bit must be a coordinate that has not been played by that player before, which we check in board section, the function update_played_tiles.

In order to give their next move to their opponent, a player must call the play function, which checks the opponent's fire coordinate on the current player's board. The move struct being created is updated with whether that fire coordinate was a hit or a miss for the opponent.

## Winning the game

Right now, the way to check when a game has been won is to count the number of hits on your hits_and_misses field on your board_state struct. Once you have 14 hits, you've won the game.