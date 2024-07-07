const std = @import("std");
const testing = std.testing;
const mutt = @import("mutt");
const sdl = @import("sdl.zig").sdl;
const Allocator = std.mem.Allocator;
const EventHandler = @import("event_handler.zig").EventHandler;

fn checkWidgetImpl(comptime T: type, comptime print_error: bool) *mutt.common.InterfaceChecker(T) {
    comptime {
        var checker = mutt.common.InterfaceChecker(T){ .print_error = print_error };
        return checker
            .isEnumStructUnion()
            .hasField("info", WidgetInfo)
            .hasFunc(.{
            .name = "init",
            .num_args = 2,
            .arg_types = &[_]type{ Allocator, *EventHandler },
            .ret_type = &[_]type{anyerror!*T}, // TODO: Replace `anyerror` w/ `Widget.Error` type
        })
            .hasFunc(.{
            .name = "deinit",
            .num_args = 2,
            .arg_types = &[_]type{ *T, Allocator },
            .ret_type = &[_]type{void},
        })
            .hasFunc(.{
            .name = "display",
            .num_args = 2,
            .arg_types = &[_]type{ *T, *sdl.SDL_Renderer },
            .ret_type = &[_]type{void},
        });
    }
}

pub fn isWidget(comptime T: type) bool {
    comptime return checkWidgetImpl(T, false).valid;
}

pub fn Widget(comptime T: type) type {
    comptime _ = checkWidgetImpl(T, true);
    return struct {
        pub fn initErased(allocator: Allocator) ErasedWidget {
            const widget: *T = T.init(allocator) catch @panic("Unable to initalize widget of type" ++ @typeName(T));
            return ErasedWidget{
                .ptr = widget,
                .deinit = (struct {
                    pub fn deinit(self: *ErasedWidget, alloc: Allocator) void {
                        self.cast(T).deinit(alloc);
                    }
                }).deinit,
                .display = (struct {
                    pub fn display(self: *ErasedWidget, renderer: *sdl.SDL_Renderer) void {
                        self.cast(T).display(renderer);
                    }
                }).display,
            };
        }
    };
}

pub const WidgetInfo = struct {
    name: ?[]const u8 = null,
    display: bool = true,
    has_children: bool = false,
    children: ?std.ArrayListUnmanaged(ErasedWidget) = null,
    parent: ?ErasedWidget = null,
};

pub const ErasedWidget = struct {
    const Self = @This();
    ptr: *anyopaque,

    // TODO: Move into `Vtable` struct?
    deinit: *const fn (*Self, Allocator) void,
    display: *const fn (*Self, *sdl.SDL_Renderer) void,

    pub fn cast(self: *Self, comptime T: type) *T {
        return @ptrCast(@alignCast(self.ptr));
    }
};

test "Create Widget" {
    const Tst = struct {
        const Self = @This();
        info: WidgetInfo = .{},

        pub usingnamespace Widget(Self);

        pub fn init(allocator: Allocator, _: *EventHandler) anyerror!*Self {
            const self = try allocator.create(Self);
            self.* = Self{};
            return self;
        }

        pub fn deinit(_: *Self, _: Allocator) void {}

        pub fn display(_: *Self, _: *sdl.SDL_Renderer) void {
            std.log.warn("Displaying `Tst`!", .{});
        }
    };

    comptime {
        if (!isWidget(Tst)) {
            @compileError("Tst doesn't implement the Widget interface");
        }
    }
}
