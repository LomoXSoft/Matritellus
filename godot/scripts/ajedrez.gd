extends RefCounted
## The rules of chess, and a player to face, for the Ajedrez humano (ajedrez_humano.gd). Written for the game from
## scratch (the user chose it, 16 November 2026, over Stockfish -- GPL, a program for each platform -- and over an
## engine in C++): no outside code, the same on Windows, Android and Linux.
##
## The board is 0x88: 128 squares, rank * 16 + file (a1 = 0, h1 = 7, a8 = 112), and a square is off the board when
## sq & 0x88 is not 0 (negative ones too). A piece is its kind (P N B R Q K = 1..6) plus 8 if it is black.
## A move is one int: from | to << 7 | promotion << 14 | flags << 17 (flags: 1 en passant, 2 castling, 4 double step).
##
## The player (search): negamax with alpha-beta, iterative deepening against the clock, captures to the end
## (quiescence), captures ordered by most valuable victim, killer moves, and a check extension. The evaluation is
## material plus the piece-square tables of Tomasz Michniewski's "Simplified Evaluation Function" (Chess Programming
## Wiki), the king's middle-game and end-game tables mixed by how much is left on the board, the bishop pair, and in
## a won ending the losing king driven to the edge. The four levels (LEVELS) are how far it looks and how badly it
## judges: the easy ones see less, add noise to what they see and now and then play a worse move on purpose.
##
## It runs on a thread of its own (ajedrez_humano.gd): the search is made on a clone(), and `stop` ends it.

const P := 1
const N := 2
const B := 3
const R := 4
const Q := 5
const K := 6
const BLACK := 8
const START := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
const MATE := 100000
const INF := 1000000
const VALUE := [0, 100, 320, 330, 500, 900, 0]
const KNIGHT := [33, 31, 18, 14, -33, -31, -18, -14]
const KING_D := [1, -1, 16, -16, 17, 15, -17, -15]
const ROOK_D := [1, -1, 16, -16]
const BISHOP_D := [17, 15, -17, -15]

## How each level plays: how deep it looks (plies), how long it may think (ms), the noise added to what it thinks of
## each move (centipawns, either way), and how often it plays one of its `among` best moves instead of the best.
## A slip is one of the next best moves, never one that loses more than `margin` against the best (nor, but at the
## first level, letting a mate go).
const LEVELS := [
	{"depth": 1, "ms": 600, "noise": 140, "slip": 0.3, "among": 6, "margin": 450},     # "Con desgana": sees one move and judges it loosely
	{"depth": 2, "ms": 1200, "noise": 45, "slip": 0.12, "among": 4, "margin": 150},    # "Entre dientes"
	{"depth": 3, "ms": 2500, "noise": 12, "slip": 0.04, "among": 2, "margin": 50},     # "En serio"
	{"depth": 6, "ms": 3800, "noise": 0, "slip": 0.0, "among": 1, "margin": 0},        # "Modo SuperChess 2.0": as deep as the clock lets it
]

# ---------------- the piece-square tables (white's view, rank 8 first, as printed) ----------------
const T_PAWN := [0, 0, 0, 0, 0, 0, 0, 0, 50, 50, 50, 50, 50, 50, 50, 50, 10, 10, 20, 30, 30, 20, 10, 10, 5, 5, 10, 25, 25, 10, 5, 5,
	0, 0, 0, 20, 20, 0, 0, 0, 5, -5, -10, 0, 0, -10, -5, 5, 5, 10, 10, -20, -20, 10, 10, 5, 0, 0, 0, 0, 0, 0, 0, 0]
const T_KNIGHT := [-50, -40, -30, -30, -30, -30, -40, -50, -40, -20, 0, 0, 0, 0, -20, -40, -30, 0, 10, 15, 15, 10, 0, -30, -30, 5, 15, 20, 20, 15, 5, -30,
	-30, 0, 15, 20, 20, 15, 0, -30, -30, 5, 10, 15, 15, 10, 5, -30, -40, -20, 0, 5, 5, 0, -20, -40, -50, -40, -30, -30, -30, -30, -40, -50]
const T_BISHOP := [-20, -10, -10, -10, -10, -10, -10, -20, -10, 0, 0, 0, 0, 0, 0, -10, -10, 0, 5, 10, 10, 5, 0, -10, -10, 5, 5, 10, 10, 5, 5, -10,
	-10, 0, 10, 10, 10, 10, 0, -10, -10, 10, 10, 10, 10, 10, 10, -10, -10, 5, 0, 0, 0, 0, 5, -10, -20, -10, -10, -10, -10, -10, -10, -20]
const T_ROOK := [0, 0, 0, 0, 0, 0, 0, 0, 5, 10, 10, 10, 10, 10, 10, 5, -5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5,
	-5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 5, 5, 0, 0, 0]
const T_QUEEN := [-20, -10, -10, -5, -5, -10, -10, -20, -10, 0, 0, 0, 0, 0, 0, -10, -10, 0, 5, 5, 5, 5, 0, -10, -5, 0, 5, 5, 5, 5, 0, -5,
	0, 0, 5, 5, 5, 5, 0, -5, -10, 5, 5, 5, 5, 5, 0, -10, -10, 0, 5, 0, 0, 0, 0, -10, -20, -10, -10, -5, -5, -10, -10, -20]
const T_KING := [-30, -40, -40, -50, -50, -40, -40, -30, -30, -40, -40, -50, -50, -40, -40, -30, -30, -40, -40, -50, -50, -40, -40, -30, -30, -40, -40, -50, -50, -40, -40, -30,
	-20, -30, -30, -40, -40, -30, -30, -20, -10, -20, -20, -20, -20, -20, -20, -10, 20, 20, 0, 0, 0, 0, 20, 20, 20, 30, 10, 0, 0, 10, 30, 20]
const T_KING_END := [-50, -40, -30, -20, -20, -30, -40, -50, -30, -20, -10, 0, 0, -10, -20, -30, -30, -10, 20, 30, 30, 20, -10, -30, -30, -10, 30, 40, 40, 30, -10, -30,
	-30, -10, 30, 40, 40, 30, -10, -30, -30, -10, 20, 30, 30, 20, -10, -30, -30, -30, 0, 0, 0, 0, -30, -30, -50, -30, -30, -30, -30, -30, -30, -50]

# built once (static: the clone on the thinking thread shares them; they are made on the main thread first)
static var _pst := PackedInt32Array()        # [colour(0/1) * 7 + kind] * 128 + sq: material + table
static var _king_end := PackedInt32Array()   # colour * 128 + sq
static var _z := PackedInt64Array()          # zobrist: piece (0..14) * 128 + sq
static var _z_castle := PackedInt64Array()
static var _z_ep := PackedInt64Array()
static var _z_side := 0
static var _castle_mask := PackedInt32Array()

var board := PackedInt32Array()
var side := 0                    # 0: white to move, 8: black
var castle := 15                 # 1 white short, 2 white long, 4 black short, 8 black long
var ep := -1                     # the square a pawn can be taken en passant on, or -1
var half := 0                    # moves since the last capture or pawn move (fifty-move rule)
var full := 1
var kings := PackedInt32Array([4, 116])
var key := 0
# the undo stack (also the game's history, for repetitions)
var hp := 0
var _um := PackedInt32Array()
var _ucap := PackedInt32Array()
var _ucas := PackedInt32Array()
var _uep := PackedInt32Array()
var _uhalf := PackedInt32Array()
var _ukey := PackedInt64Array()
# the search
var stop := false
var nodes := 0
var depth_done := 0
var _t0 := 0
var _ms := 0
var _killers := PackedInt32Array()
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_tables()
	_grow(256)
	_killers.resize(128)
	load_fen(START)

static func _tables() -> void:
	if not _pst.is_empty():
		return
	var tabs := [[], T_PAWN, T_KNIGHT, T_BISHOP, T_ROOK, T_QUEEN, T_KING]
	var pst := PackedInt32Array()
	pst.resize(14 * 128)
	var ke := PackedInt32Array()
	ke.resize(256)
	for c in range(2):
		for kind in range(1, 7):
			var t: Array = tabs[kind]
			for r in range(8):
				for f in range(8):
					var i: int = (7 - r) * 8 + f if c == 0 else r * 8 + f       # (black reads the table upside down)
					pst[(c * 7 + kind) * 128 + r * 16 + f] = int(VALUE[kind]) + int(t[i])
					if kind == K:
						ke[c * 128 + r * 16 + f] = int(T_KING_END[i])
	_king_end = ke
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261116
	var z := PackedInt64Array()
	z.resize(15 * 128)
	for i in range(z.size()):
		z[i] = _r64(rng)
	var zc := PackedInt64Array()
	zc.resize(16)
	for i in range(16):
		zc[i] = _r64(rng)
	var ze := PackedInt64Array()
	ze.resize(8)
	for i in range(8):
		ze[i] = _r64(rng)
	_z_side = _r64(rng)
	var cm := PackedInt32Array()
	cm.resize(128)
	cm.fill(15)
	cm[0] = 15 & ~2
	cm[4] = 15 & ~3
	cm[7] = 15 & ~1
	cm[112] = 15 & ~8
	cm[116] = 15 & ~12
	cm[119] = 15 & ~4
	_castle_mask = cm
	_z = z
	_z_castle = zc
	_z_ep = ze
	_pst = pst                   # (last: it is what says the tables are made)

static func _r64(rng: RandomNumberGenerator) -> int:
	return (int(rng.randi()) << 31) ^ int(rng.randi())

func _grow(n: int) -> void:
	_um.resize(n)                # (one by one: resized from inside an Array, a packed array is a copy)
	_ucap.resize(n)
	_ucas.resize(n)
	_uep.resize(n)
	_uhalf.resize(n)
	_ukey.resize(n)

## an independent copy (for the thinking thread), history and all
func clone():
	var c = get_script().new()
	c.board = board.duplicate()
	c.side = side
	c.castle = castle
	c.ep = ep
	c.half = half
	c.full = full
	c.kings = kings.duplicate()
	c.key = key
	c.hp = hp
	c._um = _um.duplicate()
	c._ucap = _ucap.duplicate()
	c._ucas = _ucas.duplicate()
	c._uep = _uep.duplicate()
	c._uhalf = _uhalf.duplicate()
	c._ukey = _ukey.duplicate()
	return c

# ---------------- positions ----------------
static func sq(file: int, rank: int) -> int:
	return rank * 16 + file

static func sq_name(s: int) -> String:
	return "abcdefgh"[s & 7] + str((s >> 4) + 1)

static func move_from(m: int) -> int:
	return m & 127

static func move_to(m: int) -> int:
	return (m >> 7) & 127

static func move_promo(m: int) -> int:
	return (m >> 14) & 7

static func move_flags(m: int) -> int:
	return m >> 17

static func _mv(from: int, to: int, promo := 0, flags := 0) -> int:
	return from | (to << 7) | (promo << 14) | (flags << 17)

func load_fen(fen: String) -> bool:
	var parts := fen.strip_edges().split(" ", false)
	if parts.size() < 2:
		return false
	board.resize(128)
	board.fill(0)
	var rank := 7
	var file := 0
	for ch in parts[0]:
		if ch == "/":
			rank -= 1
			file = 0
		elif ch >= "1" and ch <= "8":
			file += int(ch)
		else:
			var kind: int = "pnbrqk".find(ch.to_lower()) + 1
			if kind <= 0 or rank < 0 or file > 7:
				return false
			board[sq(file, rank)] = kind | (BLACK if ch == ch.to_lower() else 0)
			if kind == K:
				kings[0 if ch == "K" else 1] = sq(file, rank)
			file += 1
	side = 0 if parts[1] == "w" else BLACK
	castle = 0
	if parts.size() > 2:
		for ch in parts[2]:
			castle |= {"K": 1, "Q": 2, "k": 4, "q": 8}.get(ch, 0)
	ep = -1
	if parts.size() > 3 and parts[3] != "-" and parts[3].length() == 2:
		ep = sq("abcdefgh".find(parts[3][0]), int(parts[3][1]) - 1)
	half = int(parts[4]) if parts.size() > 4 else 0
	full = int(parts[5]) if parts.size() > 5 else 1
	hp = 0
	key = _hash()
	return true

func fen() -> String:
	var out := ""
	for rank in range(7, -1, -1):
		var gap := 0
		for file in range(8):
			var pc: int = board[sq(file, rank)]
			if pc == 0:
				gap += 1
				continue
			if gap > 0:
				out += str(gap)
				gap = 0
			var ch: String = " pnbrqk"[pc & 7]
			out += ch if pc & BLACK else ch.to_upper()
		if gap > 0:
			out += str(gap)
		if rank > 0:
			out += "/"
	var cas := ""
	for k in [[1, "K"], [2, "Q"], [4, "k"], [8, "q"]]:
		if castle & int(k[0]):
			cas += String(k[1])
	return "%s %s %s %s %d %d" % [out, "b" if side else "w", cas if cas != "" else "-", sq_name(ep) if ep >= 0 else "-", half, full]

func _hash() -> int:
	var h := 0
	for s in range(128):
		if s & 0x88 == 0 and board[s] != 0:
			h ^= _z[board[s] * 128 + s]
	h ^= _z_castle[castle]
	if ep >= 0:
		h ^= _z_ep[ep & 7]
	if side:
		h ^= _z_side
	return h

# ---------------- attacks and moves ----------------
## is square s attacked by the side `by` (0 white, 8 black)?
func attacked(s: int, by: int) -> bool:
	var t: int
	if by == 0:
		t = s - 15
		if t & 0x88 == 0 and board[t] == P:
			return true
		t = s - 17
		if t & 0x88 == 0 and board[t] == P:
			return true
	else:
		t = s + 15
		if t & 0x88 == 0 and board[t] == (P | BLACK):
			return true
		t = s + 17
		if t & 0x88 == 0 and board[t] == (P | BLACK):
			return true
	for d: int in KNIGHT:
		t = s + d
		if t & 0x88 == 0 and board[t] == (N | by):
			return true
	for d: int in KING_D:
		t = s + d
		if t & 0x88 == 0 and board[t] == (K | by):
			return true
	for d: int in ROOK_D:
		t = s + d
		while t & 0x88 == 0:
			var pc: int = board[t]
			if pc != 0:
				if pc == (R | by) or pc == (Q | by):
					return true
				break
			t += d
	for d: int in BISHOP_D:
		t = s + d
		while t & 0x88 == 0:
			var pc: int = board[t]
			if pc != 0:
				if pc == (B | by) or pc == (Q | by):
					return true
				break
			t += d
	return false

func in_check() -> bool:
	return attacked(kings[side >> 3], side ^ BLACK)

## the moves the side to move could make, leaving aside whether its king is left in check (`caps`: only captures and
## queening, for the search's last steps)
func gen(caps := false) -> PackedInt32Array:
	var out := PackedInt32Array()
	var me := side
	var them := side ^ BLACK
	var s := 0
	while s < 120:
		if s & 8:
			s += 8
			continue
		var pc: int = board[s]
		if pc == 0 or (pc & BLACK) != me:
			s += 1
			continue
		var kind: int = pc & 7
		if kind == P:
			var up: int = 16 if me == 0 else -16
			var last: int = 7 if me == 0 else 0
			var first: int = 1 if me == 0 else 6
			var t: int = s + up
			if t & 0x88 == 0 and board[t] == 0:
				if (t >> 4) == last:
					out.append(_mv(s, t, Q))
					if not caps:
						out.append(_mv(s, t, R))
						out.append(_mv(s, t, B))
						out.append(_mv(s, t, N))
				elif not caps:
					out.append(_mv(s, t))
					if (s >> 4) == first and board[t + up] == 0:
						out.append(_mv(s, t + up, 0, 4))
			for side_d: int in [-1, 1]:
				t = s + up + side_d
				if t & 0x88:
					continue
				var v: int = board[t]
				if v != 0 and (v & BLACK) == them:
					if (t >> 4) == last:
						out.append(_mv(s, t, Q))
						if not caps:
							out.append(_mv(s, t, R))
							out.append(_mv(s, t, B))
							out.append(_mv(s, t, N))
					else:
						out.append(_mv(s, t))
				elif t == ep:
					out.append(_mv(s, t, 0, 1))
		elif kind == N or kind == K:
			for d: int in (KNIGHT if kind == N else KING_D):
				var t: int = s + d
				if t & 0x88:
					continue
				var v: int = board[t]
				if v == 0:
					if not caps:
						out.append(_mv(s, t))
				elif (v & BLACK) == them:
					out.append(_mv(s, t))
			if kind == K and not caps:
				_castles(out, s)
		else:
			var dirs: Array = ROOK_D if kind == R else (BISHOP_D if kind == B else KING_D)
			for d: int in dirs:
				var t: int = s + d
				while t & 0x88 == 0:
					var v: int = board[t]
					if v == 0:
						if not caps:
							out.append(_mv(s, t))
					else:
						if (v & BLACK) == them:
							out.append(_mv(s, t))
						break
					t += d
		s += 1
	return out

func _castles(out: PackedInt32Array, s: int) -> void:
	var them := side ^ BLACK
	if side == 0 and s == 4:
		if castle & 1 and board[5] == 0 and board[6] == 0 and board[7] == R and not attacked(4, them) and not attacked(5, them) and not attacked(6, them):
			out.append(_mv(4, 6, 0, 2))
		if castle & 2 and board[3] == 0 and board[2] == 0 and board[1] == 0 and board[0] == R and not attacked(4, them) and not attacked(3, them) and not attacked(2, them):
			out.append(_mv(4, 2, 0, 2))
	elif side == BLACK and s == 116:
		if castle & 4 and board[117] == 0 and board[118] == 0 and board[119] == (R | BLACK) and not attacked(116, them) and not attacked(117, them) and not attacked(118, them):
			out.append(_mv(116, 118, 0, 2))
		if castle & 8 and board[115] == 0 and board[114] == 0 and board[113] == 0 and board[112] == (R | BLACK) and not attacked(116, them) and not attacked(115, them) and not attacked(114, them):
			out.append(_mv(116, 114, 0, 2))

## Makes a move. If it leaves the mover's own king in check it is taken back and false is returned.
func make(m: int) -> bool:
	var fr: int = m & 127
	var to: int = (m >> 7) & 127
	var pr: int = (m >> 14) & 7
	var fl: int = m >> 17
	var pc: int = board[fr]
	var cap: int = board[to]
	if hp >= _um.size():
		_grow(_um.size() * 2)
	_um[hp] = m
	_ucas[hp] = castle
	_uep[hp] = ep
	_uhalf[hp] = half
	_ukey[hp] = key
	var k := key
	if ep >= 0:
		k ^= _z_ep[ep & 7]
	half += 1
	if cap != 0:
		k ^= _z[cap * 128 + to]
		half = 0
	board[to] = pc
	board[fr] = 0
	k ^= _z[pc * 128 + fr] ^ _z[pc * 128 + to]
	if (pc & 7) == P:
		half = 0
		if fl & 1:                                # en passant: the pawn taken is beside, not on the square
			var behind: int = to - 16 if side == 0 else to + 16
			cap = board[behind]
			board[behind] = 0
			k ^= _z[cap * 128 + behind]
		elif pr != 0:
			board[to] = pr | side
			k ^= _z[pc * 128 + to] ^ _z[(pr | side) * 128 + to]
	elif (pc & 7) == K:
		kings[side >> 3] = to
		if fl & 2:                                # castling: the rook comes over too
			var rf: int
			var rt: int
			match to:
				6:
					rf = 7; rt = 5
				2:
					rf = 0; rt = 3
				118:
					rf = 119; rt = 117
				_:
					rf = 112; rt = 115
			var rook: int = board[rf]
			board[rt] = rook
			board[rf] = 0
			k ^= _z[rook * 128 + rf] ^ _z[rook * 128 + rt]
	_ucap[hp] = cap
	hp += 1
	ep = -1
	if fl & 4:
		ep = (fr + to) >> 1
		k ^= _z_ep[ep & 7]
	var nc: int = castle & _castle_mask[fr] & _castle_mask[to]
	if nc != castle:
		k ^= _z_castle[castle] ^ _z_castle[nc]
		castle = nc
	if side == BLACK:
		full += 1
	side ^= BLACK
	key = k ^ _z_side
	if attacked(kings[(side ^ BLACK) >> 3], side):
		undo()
		return false
	return true

func undo() -> void:
	hp -= 1
	var m: int = _um[hp]
	var fr: int = m & 127
	var to: int = (m >> 7) & 127
	var pr: int = (m >> 14) & 7
	var fl: int = m >> 17
	side ^= BLACK
	if side == BLACK:
		full -= 1
	var pc: int = board[to]
	if pr != 0:
		pc = P | side
	board[fr] = pc
	if fl & 1:
		board[to] = 0
		board[to - 16 if side == 0 else to + 16] = _ucap[hp]
	else:
		board[to] = _ucap[hp]
	if (pc & 7) == K:
		kings[side >> 3] = fr
		if fl & 2:
			match to:
				6:
					board[7] = board[5]; board[5] = 0
				2:
					board[0] = board[3]; board[3] = 0
				118:
					board[119] = board[117]; board[117] = 0
				_:
					board[112] = board[115]; board[115] = 0
	castle = _ucas[hp]
	ep = _uep[hp]
	half = _uhalf[hp]
	key = _ukey[hp]

## the moves that can really be made
func legal() -> PackedInt32Array:
	var out := PackedInt32Array()
	for m: int in gen():
		if make(m):
			undo()
			out.append(m)
	return out

func legal_from(s: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for m: int in legal():
		if (m & 127) == s:
			out.append(m)
	return out

## the same position has been seen before (with the same side to move) since the last capture or pawn move
func _repeated(times: int) -> bool:
	var seen := 0
	var i := hp - 2
	var stop_at: int = maxi(0, hp - half)
	while i >= stop_at:
		if _ukey[i] == key:
			seen += 1
			if seen >= times:
				return true
		i -= 2
	return false

func _bare() -> bool:
	var minors := 0
	for s in range(120):
		if s & 0x88:
			continue
		var kind: int = board[s] & 7
		if kind == P or kind == R or kind == Q:
			return false
		if kind == N or kind == B:
			minors += 1
	return minors <= 1

## how the game stands: "" (on), "mate" (the side to move is mated), "stalemate", "fifty", "repeat", "material"
func status() -> String:
	if legal().is_empty():
		return "mate" if in_check() else "stalemate"
	if half >= 100:
		return "fifty"
	if _repeated(2):
		return "repeat"
	if _bare():
		return "material"
	return ""

## The move in short algebraic notation, with the letters of the language (es: R D T A C; en: K Q R B N), before
## it is made.
func san(m: int, es := true) -> String:
	var fr: int = m & 127
	var to: int = (m >> 7) & 127
	var pr: int = (m >> 14) & 7
	var fl: int = m >> 17
	var kind: int = board[fr] & 7
	var letters: String = " PCATDR" if es else " PNBRQK"
	var out := ""
	if fl & 2:
		out = "O-O" if (to & 7) == 6 else "O-O-O"
	else:
		var takes: bool = board[to] != 0 or (fl & 1) != 0
		if kind == P:
			if takes:
				out = "abcdefgh"[fr & 7] + "x"
			out += sq_name(to)
			if pr != 0:
				out += "=" + letters[pr]
		else:
			out = letters[kind]
			var same := false
			var same_file := false
			var same_rank := false
			for o: int in legal():
				var of: int = o & 127
				if o != m and ((o >> 7) & 127) == to and of != fr and (board[of] & 7) == kind:
					same = true
					same_file = same_file or (of & 7) == (fr & 7)
					same_rank = same_rank or (of >> 4) == (fr >> 4)
			if same:
				if not same_file:
					out += "abcdefgh"[fr & 7]
				elif not same_rank:
					out += str((fr >> 4) + 1)
				else:
					out += sq_name(fr)
			if takes:
				out += "x"
			out += sq_name(to)
	if make(m):
		if in_check():
			out += "#" if legal().is_empty() else "+"
		undo()
	return out

## positions counted move by move (the tests: the move generator against the known figures)
func perft(depth: int) -> int:
	if depth == 0:
		return 1
	var n := 0
	for m: int in gen():
		if make(m):
			n += perft(depth - 1)
			undo()
	return n

# ---------------- what a position is worth ----------------
## from the side to move's point of view, in centipawns
func evaluate() -> int:
	var score := 0
	var phase := 0
	var bishops := [0, 0]
	var mat := [0, 0]
	for s in range(120):
		if s & 0x88:
			continue
		var pc: int = board[s]
		if pc == 0:
			continue
		var kind: int = pc & 7
		var c: int = pc >> 3
		var v: int = _pst[(c * 7 + kind) * 128 + s]
		if kind == B:
			bishops[c] += 1
		if kind != K and kind != P:
			phase += [0, 0, 1, 1, 2, 4, 0][kind]
			mat[c] += int(VALUE[kind])
		elif kind == P:
			mat[c] += 100
		if kind == K:
			continue                              # (the king, mixed below)
		score += v if c == 0 else -v
	phase = mini(phase, 24)
	for c in range(2):
		var ks: int = kings[c]
		var mid: int = _pst[(c * 7 + K) * 128 + ks]
		var end: int = _king_end[c * 128 + ks]
		var kv: int = (mid * phase + end * (24 - phase)) / 24
		score += kv if c == 0 else -kv
		if bishops[c] >= 2:
			score += 30 if c == 0 else -30
	# a won ending: the stronger side brings its king up and drives the other to the edge
	if phase <= 6 and absi(mat[0] - mat[1]) >= 300:
		var strong: int = 0 if mat[0] > mat[1] else 1
		var weak_k: int = kings[1 - strong]
		var wf: int = weak_k & 7
		var wr: int = weak_k >> 4
		var edge: int = maxi(3 - wf, wf - 4) + maxi(3 - wr, wr - 4)
		var near: int = absi((kings[strong] & 7) - wf) + absi((kings[strong] >> 4) - wr)
		var push: int = edge * 12 + (14 - near) * 5
		score += push if strong == 0 else -push
	return score if side == 0 else -score

# ---------------- the search ----------------
## The move to play, for this level (0..3): thinks until it is sure or until its time is up. 0 if there is none.
func best(level: int) -> int:
	var cfg: Dictionary = LEVELS[clampi(level, 0, LEVELS.size() - 1)]
	stop = false
	nodes = 0
	depth_done = 0
	_t0 = Time.get_ticks_msec()
	_ms = int(cfg["ms"])
	_killers.fill(0)
	_rng.randomize()
	var roots: Array = []                         # [move, noise, score, exact score]
	for m: int in legal():
		roots.append([m, _rng.randi_range(-int(cfg["noise"]), int(cfg["noise"])) if int(cfg["noise"]) > 0 else 0, 0, 0])
	if roots.is_empty():
		return 0
	if roots.size() == 1:
		return roots[0][0]
	roots.shuffle()                               # (between moves that come out the same, a different one each game)
	var full_window: bool = int(cfg["noise"]) > 0     # (the noisy levels need every move's own worth, not just "worse")
	var done_scores: Array = []
	for d in range(1, int(cfg["depth"]) + 1):
		var alpha := -INF
		var all_done := true
		for r: Array in roots:
			if not make(int(r[0])):
				continue
			var s: int = -_search(d - 1, -INF, -alpha if not full_window else INF, 1)
			undo()
			if stop:
				all_done = false
				break
			r[3] = s
			if full_window:
				r[2] = s + int(r[1]) if absi(s) < MATE - 100 else s       # (a mate is a mate, noise or not)
			elif s > alpha:
				alpha = s
				r[2] = s
			else:
				r[2] = s - 1                      # (a bound only: below the best, whatever it is)
		if not all_done:
			break
		depth_done = d
		roots.sort_custom(func(a, b): return int(a[2]) > int(b[2]))
		done_scores = roots.duplicate()
		if absi(int(roots[0][2])) >= MATE - 100:
			break                                 # (a mate found: no need to look further)
		if Time.get_ticks_msec() - _t0 > _ms / 2:
			break                                 # (the next depth would not be finished in time)
	if done_scores.is_empty():
		return roots[0][0]
	var top: int = int(done_scores[0][3])
	var among: int = mini(int(cfg["among"]), done_scores.size())
	if among > 1 and _rng.randf() < float(cfg["slip"]) and (top < MATE - 100 or level == 0):
		var near: Array = done_scores.slice(1, among).filter(func(r): return top - int(r[3]) <= int(cfg["margin"]))
		if not near.is_empty():
			return near[_rng.randi() % near.size()][0]               # (a slip: one of the next best, not far off it)
	return done_scores[0][0]

func _clock() -> void:
	if (nodes & 511) == 0 and Time.get_ticks_msec() - _t0 > _ms:
		stop = true

func _order(moves: PackedInt32Array, ply: int) -> PackedInt64Array:
	var keyed := PackedInt64Array()
	keyed.resize(moves.size())
	var k1: int = _killers[ply * 2] if ply < 64 else 0
	var k2: int = _killers[ply * 2 + 1] if ply < 64 else 0
	for i in range(moves.size()):
		var m: int = moves[i]
		var to: int = (m >> 7) & 127
		var victim: int = board[to] & 7
		var score := 1000
		if victim != 0:
			score = 20000 + victim * 100 - (board[m & 127] & 7)
		elif (m >> 17) & 1:
			score = 20100
		elif m == k1:
			score = 9000
		elif m == k2:
			score = 8000
		if (m >> 14) & 7 == Q:
			score += 15000
		keyed[i] = (score << 20) | m
	keyed.sort()
	return keyed

func _search(depth: int, alpha: int, beta: int, ply: int) -> int:
	nodes += 1
	_clock()
	if stop:
		return 0
	if half >= 100 or _repeated(1):
		return 0
	var check := in_check()
	if check and ply < 24:
		depth += 1
	if depth <= 0:
		return _quiet(alpha, beta, ply)
	var keyed := _order(gen(), ply)
	var legal_n := 0
	var best_s := -INF
	var i := keyed.size() - 1
	while i >= 0:
		var m: int = keyed[i] & 0xFFFFF
		i -= 1
		if not make(m):
			continue
		legal_n += 1
		var s: int = -_search(depth - 1, -beta, -alpha, ply + 1)
		undo()
		if stop:
			return 0
		if s > best_s:
			best_s = s
		if s > alpha:
			alpha = s
			if alpha >= beta:
				if board[(m >> 7) & 127] == 0 and ply < 64 and _killers[ply * 2] != m:
					_killers[ply * 2 + 1] = _killers[ply * 2]
					_killers[ply * 2] = m
				break
	if legal_n == 0:
		return -MATE + ply if check else 0
	return best_s

func _quiet(alpha: int, beta: int, ply: int) -> int:
	nodes += 1
	_clock()
	if stop:
		return 0
	var stand := evaluate()
	if stand >= beta or ply > 40:
		return stand
	if stand > alpha:
		alpha = stand
	var keyed := _order(gen(true), ply)
	var i := keyed.size() - 1
	while i >= 0:
		var m: int = keyed[i] & 0xFFFFF
		i -= 1
		var victim: int = board[(m >> 7) & 127] & 7
		if (m >> 14) & 7 == 0 and stand + int(VALUE[victim]) + 200 < alpha:
			continue                              # (even taking it for nothing would not be enough)
		if not make(m):
			continue
		var s: int = -_quiet(-beta, -alpha, ply + 1)
		undo()
		if stop:
			return 0
		if s >= beta:
			return s
		if s > alpha:
			alpha = s
	return alpha
