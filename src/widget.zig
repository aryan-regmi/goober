const std = @import("std");
const testing = std.testing;
const mutt = @import("mutt");

fn checkWidgetImpl(comptime T: type, comptime print_error: bool) *mutt.common.InterfaceChecker(T) {
    comptime {
        var checker = mutt.common.InterfaceChecker(T){ .print_error = print_error };
        return checker.hasFunc(.{
            .name = "hasChildren",
            .num_args = 1,
            .arg_types = &[_]type{*const T},
            .ret_type = &[_]type{bool},
        });
    }
}

pub fn isWidget(comptime T: type) bool {
    comptime return checkWidgetImpl(T, false).valid;
}

pub fn Widget(comptime T: type) type {
    comptime _ = checkWidgetImpl(T, true);
    return struct {};
}

test "Create Widget" {
    const Tst = struct {
        const Self = @This();
        pub usingnamespace Widget(Self);

        pub fn hasChildren(_: *const Self) bool {
            return false;
        }
    };

    comptime {
        if (!isWidget(Tst)) {
            @compileError("Tst doesn't implement the Widget interface");
        }
    }
}
