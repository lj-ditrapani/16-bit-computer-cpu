###
Author:  Lyall Jonathan Di Trapani
16 bit CPU simulator
---------|---------|---------|---------|---------|---------|---------|--
###


END = 0


getNibbles = (word) ->
  opCode = word >> 12
  a = (word >> 8) & 0xF
  b = (word >> 4) & 0xF
  c = word & 0xF
  [opCode, a, b, c]


isPositiveOrZero = (word) ->
  (word >> 15) == 0


isNegative = (word) ->
  (word >> 15) == 1


isTruePositive = (word) ->
  isPositiveOrZero(word) and (word != 0)


hasOverflowedOnAdd = (a, b, sum) ->
  ((isNegative(a) and isNegative(b) and isPositiveOrZero(sum)) or
   (isPositiveOrZero(a) and isPositiveOrZero(b) and isNegative(sum)))


class CPU
  constructor: ->
    @reset()
    @opCodes = ('END HBY LBY LOD STR ADD SUB ADI SBI AND' +
                 ' ORR XOR NOT SHF BRN SPC').split(' ')

  reset: ->
    @pc = 0
    @registers = (0 for _ in [0...16])
    @rom = (0 for _ in [0...Math.pow(2, 16)])
    @ram = (0 for _ in [0...Math.pow(2, 16)])
    @carry = 0
    @overflow = 0

  step: ->
    instruction = @rom[@pc]
    [opCode, a, b, c] = getNibbles instruction
    if opCode == END
      true
    else
      [jump, address] = this[@opCodes[opCode]](a, b, c)
      @pc = if jump is true then address else @pc + 1
      false

  add: (a, b, carry) ->
    sum = a + b + carry
    @carry = Number(sum >= Math.pow(2, 16))
    sum = sum & 0xFFFF
    @overflow = Number(hasOverflowedOnAdd(a, b, sum))
    sum

  HBY: (highNibble, lowNibble, register) ->
    immediate8 = (highNibble << 4) | lowNibble
    value = @registers[register]
    @registers[register] = (immediate8 << 8) | (value & 0x00FF)

  LBY: (highNibble, lowNibble, register) ->
    immediate8 = (highNibble << 4) | lowNibble
    value = @registers[register]
    @registers[register] = (value & 0xFF00) | immediate8

  LOD: (ra, _, rd) ->
    address = @registers[ra]
    @registers[rd] = @ram[address]

  STR: (ra, r2, _) ->
    address = @registers[ra]
    value = @registers[r2]
    @ram[address] = value

  ADD: (r1, r2, rd) ->
    [a, b] = [@registers[r1], @registers[r2]]
    sum = @add a, b, 0
    @registers[rd] = sum

  SUB: (r1, r2, rd) ->
    [a, b] = [@registers[r1], @registers[r2]]
    notB = b ^ 0xFFFF
    diff = @add a, notB, 1
    @registers[rd] = diff

  ADI: (r1, immd, rd) ->
    a = @registers[r1]
    sum = @add a, immd, 0
    @registers[rd] = sum

  SBI: (r1, immd, rd) ->
    a = @registers[r1]
    notB = immd ^ 0xFFFF
    diff = @add a, notB, 1
    @registers[rd] = diff

  SPC: (_, __, rd) ->
    @registers[rd] = @pc + 2


export_globals = (exports) ->
  if module?.exports?
    module.exports = exports
  else
    if not ljd?
      ljd = {}
    ljd.cpu16bit = exports

export_globals {
  CPU,
  getNibbles
}
