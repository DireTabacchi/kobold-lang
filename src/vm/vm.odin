package vm

import "kobold:code"
import "kobold:object"

Op_Code :: code.Op_Code

STACK_MAX :: 4096

Virtual_Machine :: struct {
    chunk: code.Chunk,
    stack: [STACK_MAX]object.Value,

    ip: int,
    sp: int,
}

vm_init :: proc(vm: ^Virtual_Machine, chunk: code.Chunk) {
    vm.chunk = chunk
    vm.ip = 0
    vm.sp = 0
}

pop :: proc(vm: ^Virtual_Machine) -> object.Value {
    val := vm.stack[vm.sp-1]
    vm.sp -= 1
    return val
}

push :: proc(vm: ^Virtual_Machine, val: object.Value) {
    vm.stack[vm.sp] = val
    vm.sp += 1
}

run :: proc(vm: ^Virtual_Machine) {
    for {
        op_bc := vm.chunk.code[vm.ip]
        switch op_bc {
        case byte(Op_Code.PUSHC):
            push(vm, vm.chunk.constants[read_u16(vm)])
        case byte(Op_Code.ADD):
            exec_binary_op(vm, op_bc)
        case byte(Op_Code.SUB):
            exec_binary_op(vm, op_bc)
        case byte(Op_Code.MULT):
            exec_binary_op(vm, op_bc)
        case byte(Op_Code.DIV):
            exec_binary_op(vm, op_bc)
        case byte(Op_Code.MOD):
            exec_binary_op(vm, op_bc)
        case byte(Op_Code.MODF):
            exec_binary_op(vm, op_bc)
        case byte(Op_Code.NEG):
            exec_unary_op(vm, op_bc)
        case byte(Op_Code.RET):
            return
        }

        vm.ip += 1
    }
}

read_u16 :: proc(vm: ^Virtual_Machine) -> u16 {
    hi := vm.chunk.code[vm.ip+1]
    lo := vm.chunk.code[vm.ip+2]
    idx : u16 = (u16(hi) << 8) | u16(lo)
    vm.ip += 2
    return idx
}

exec_binary_op :: proc(vm: ^Virtual_Machine, op: byte) {
    switch op {
    case byte(Op_Code.ADD):
        b := pop(vm)
        a := pop(vm)
        res: object.Value
        res.value = a.value.(i64) + b.value.(i64)
        res.type = a.type
        push(vm, res)
    case byte(Op_Code.SUB):
        b := pop(vm)
        a := pop(vm)
        res: object.Value
        res.value = a.value.(i64) - b.value.(i64)
        res.type = a.type
        push(vm, res)
    case byte(Op_Code.MULT):
        b := pop(vm)
        a := pop(vm)
        res: object.Value
        res.value = a.value.(i64) * b.value.(i64)
        res.type = a.type
        push(vm, res)
    case byte(Op_Code.DIV):
        b := pop(vm)
        a := pop(vm)
        res: object.Value
        res.value = a.value.(i64) / b.value.(i64)
        res.type = a.type
        push(vm, res)
    case byte(Op_Code.MOD):
        b := pop(vm)
        a := pop(vm)
        res: object.Value
        res.value = a.value.(i64) % b.value.(i64)
        res.type = a.type
        push(vm, res)
    case byte(Op_Code.MODF):
        b := pop(vm)
        a := pop(vm)
        res: object.Value
        res.value = a.value.(i64) %% b.value.(i64)
        res.type = a.type
        push(vm, res)
    }
}

exec_unary_op :: proc(vm: ^Virtual_Machine, op: byte) {
    switch op {
    case byte(Op_Code.NEG):
        val := pop(vm)
        switch val.type {
        case .Integer:
            val.value = -val.value.(i64)
            push(vm, val)
            return
        }
    }
}
