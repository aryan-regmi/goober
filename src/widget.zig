const std = @import("std");
const testing = std.testing;

// TODO: Add checks to make sure `T` implments `Widget` correctly!

pub const Widget = struct {
    const Self = @This();

    pub const Vtable = struct {
        deinitFn: *const fn (self: *Widget, allocator: std.mem.Allocator) void,
        showFn: *const fn (self: *Widget) anyerror!void,
        getParentFn: *const fn (self: *Widget) ?*Widget,
        isDisplayedFn: *const fn (self: *Widget) bool,
    };

    pub const Info = struct {
        has_children: bool = false,
        children: ?std.ArrayListUnmanaged(Widget) = null,
        parent: ?*Self = null,
        name: ?[]const u8 = null,
    };

    component: *anyopaque,
    vtable: *const Vtable,

    pub fn init(component: *anyopaque, vtable: *const Vtable) Self {
        return Self{
            .component = component,
            .vtable = vtable,
        };
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        return self.vtable.deinitFn(self, allocator);
    }

    pub fn show(self: *Self) anyerror!void {
        return self.vtable.showFn(self);
    }

    pub fn getParent(self: *Self) ?*Self {
        return self.vtable.getParentFn(self);
    }

    pub fn isDisplayed(self: *Self) bool {
        return self.vtable.isDisplayedFn(self);
    }

    pub fn isType(self: *const Self, comptime T: type) bool {
        return self.vtable == &T.Vtable;
    }

    pub fn castUnchecked(self: *const Self, comptime T: type) *T {
        return @ptrCast(@alignCast(self.component));
    }

    pub fn cast(self: *const Self, comptime T: type) ?*T {
        if (self.isType(T)) {
            return self.castUnchecked(T);
        }
        return null;
    }
};

test "Create widget" {
    const Custom = struct {
        pub const Vtable = Widget.Vtable{
            .deinitFn = undefined,
            .showFn = undefined,
            .getParentFn = undefined,
            .isDisplayedFn = undefined,
        };
    };

    var custom = Custom{};
    const custom_widget = Widget.init(&custom, &Custom.Vtable);

    try testing.expect(custom_widget.isType(Custom));

    const cast = custom_widget.cast(Custom);
    try testing.expectEqual(&custom, cast.?);
}
