package vm

//import "core:fmt"
import "kobold:object"

FREE_TRIGGER :: 256

Garbage_Collector :: struct {
    objects: [dynamic]^object.Object,
    garbage: [dynamic]^object.Object,
}

track_object :: proc(gc: ^Garbage_Collector, obj: ^object.Object) {
    append(&gc.objects, obj)
}

collect :: proc(gc: ^Garbage_Collector) {
    for i := 0; i < len(gc.objects); {
        if gc.objects[i].ref_count == 0 {
            g := gc.objects[i]
            unordered_remove(&gc.objects, i)
            append(&gc.garbage, g)
        } else {
            i += 1
        }
    }
}

garbage_upkeep :: proc(gc: ^Garbage_Collector) {
    if len(gc.garbage) >= FREE_TRIGGER {
        for len(gc.garbage) > 0 {
            garbage_val := gc.garbage[0]
            if arr_val, is_arr := garbage_val.value.(object.Array); is_arr {
                delete(arr_val.data)
            }
            free(garbage_val)
            unordered_remove(&gc.garbage, 0)
        }
    }
}

garbage_free :: proc(gc: ^Garbage_Collector) {
    for len(gc.garbage) > 0 {
        garbage_val := gc.garbage[0]
        if arr_val, is_arr := garbage_val.value.(object.Array); is_arr {
            delete(arr_val.data)
        }
        free(garbage_val)
        unordered_remove(&gc.garbage, 0)
    }
}

program_free :: proc(gc: ^Garbage_Collector) {
    garbage_free(gc)

    for len(gc.objects) > 0 {
        obj_val := gc.objects[0]
        if arr_val, is_arr := obj_val.value.(object.Array); is_arr {
            delete(arr_val.data)
        }
        free(obj_val)
        unordered_remove(&gc.objects, 0)
    }
}

gc_destroy :: proc(gc: ^Garbage_Collector) {
    delete(gc.objects)
    delete(gc.garbage)
}
