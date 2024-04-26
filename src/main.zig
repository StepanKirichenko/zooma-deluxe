const std = @import("std");
const rl = @import("rl.zig");

const Vec = rl.Vector2;

const Input = struct {
    movement: Vec,
};

const BG_COLOR = rl.Color{ .r = 255, .g = 200, .b = 200, .a = 255 };

const SPEED: f32 = 100;

fn readInput() Input {
    var movement_x: f32 = 0;
    var movement_y: f32 = 0;
    if (rl.isKeyDown(.d)) {
        movement_x += 1;
    }
    if (rl.isKeyDown(.a)) {
        movement_x -= 1;
    }
    if (rl.isKeyDown(.w)) {
        movement_y -= 1;
    }
    if (rl.isKeyDown(.s)) {
        movement_y += 1;
    }

    return Input{
        .movement = Vec{ .x = movement_x, .y = movement_y },
    };
}

pub fn main() !void {
    std.debug.print("Hello, world!\n", .{});

    rl.initWindow(800, 600, "Raylib window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var circle_pos = Vec{ .x = 100, .y = 200 };

    while (!rl.windowShouldClose()) {
        // Frame update
        const delta = rl.getFrameTime();
        const input = readInput();

        const move = rl.vector2Scale(input.movement, SPEED * delta);
        circle_pos = rl.vector2Add(circle_pos, move);

        // Rendering
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(BG_COLOR);

        const circle_radius: f32 = 40.0;
        const circle_color = rl.Color{ .b = 255, .a = 255 };
        rl.drawCircleV(circle_pos, circle_radius, circle_color);
    }
}
