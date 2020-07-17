/*
* Copyright (c) 2020 Alecaddd (https://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

using Akira.Lib.Models;
using Akira.Lib.Managers;

public class Akira.Utils.AffineTransform : Object {
    private const int MIN_SIZE = 1;
    private const int MIN_POS = 10;
    private const double ROTATION_FIXED_STEP = 15.0;

    public static double prev_rotation_difference = 0.0;

    public static HashTable<string, double?> get_position (CanvasItem item) {
        HashTable<string, double?> array = new HashTable<string, double?> (str_hash, str_equal);
        double item_x = item.get_coords ("x");
        double item_y = item.get_coords ("y");

        item.canvas.convert_from_item_space (item, ref item_x, ref item_y);

        if (item.artboard != null) {
            item_x = item.relative_x;
            item_y = item.relative_y;
        }

        array.insert ("x", item_x);
        array.insert ("y", item_y);

        return array;
    }

    public static void set_position (CanvasItem item, double? x = null, double? y = null) {
        if (item.artboard != null) {
            item.relative_x = x != null ? x : item.relative_x;
            item.relative_y = y != null ? y : item.relative_y;
            return;
        }

        var matrix = item.get_real_transform ();
        //  double new_x = (x != null) ? x : matrix.x0;
        //  double new_y = (y != null) ? y : matrix.y0;
        matrix.x0 = (x != null) ? x : matrix.x0;
        matrix.y0 = (y != null) ? y : matrix.y0;

        //  var new_matrix = Cairo.Matrix (matrix.xx, matrix.yx, matrix.xy, matrix.yy, new_x, new_y);
        item.set_transform (matrix);
    }

    /**
     * Move the item based on the mouse click and drag event.
     */
    public static void move_from_event (
        CanvasItem item,
        double event_x,
        double event_y,
        ref double initial_event_x,
        ref double initial_event_y
    ) {
        var delta_x = event_x - initial_event_x;
        var delta_y = event_y - initial_event_y;

        if (item.artboard != null) {
            item.relative_x += delta_x;
            item.relative_y += delta_y;
        } else {
            var matrix = item.get_real_transform ();
            matrix.x0 += delta_x;
            matrix.y0 += delta_y;
            item.set_transform (matrix);
        }

        initial_event_x = event_x;
        initial_event_y = event_y;
    }

    public static void scale_from_event (
        double x,
        double y,
        ref double initial_x,
        ref double initial_y,
        ref double delta_x_accumulator,
        ref double delta_y_accumulator,
        double initial_width,
        double initial_height,
        NobManager.Nob selected_nob,
        CanvasItem selected_item
    ) {
        double delta_x = Math.round (x - initial_x);
        double delta_y = Math.round (y - initial_y);

        var canvas = selected_item.canvas;

        double origin_move_delta_x = 0;
        double origin_move_delta_y = 0;

        double item_width = selected_item.get_coords ("width");
        double item_height = selected_item.get_coords ("height");

        double new_width = initial_width;
        double new_height = initial_height;

        switch (selected_nob) {
            case NobManager.Nob.TOP_LEFT:
                new_height = initial_height - delta_y;
                new_width = initial_width - delta_x;
                if (canvas.ctrl_is_pressed || selected_item.size_locked) {
                    new_width = GLib.Math.round (new_height * selected_item.size_ratio);
                }

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;

            case NobManager.Nob.TOP_CENTER:
                new_height = initial_height - delta_y;
                if (canvas.ctrl_is_pressed || selected_item.size_locked) {
                    new_width = GLib.Math.round (new_height * selected_item.size_ratio);
                }

                origin_move_delta_y = item_height - new_height;
                break;

            case NobManager.Nob.TOP_RIGHT:
                new_width = initial_width + delta_x;
                new_height = initial_height - delta_y;
                if (canvas.ctrl_is_pressed || selected_item.size_locked) {
                    new_height = GLib.Math.round (new_width / selected_item.size_ratio);
                }

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }
                break;

            case NobManager.Nob.RIGHT_CENTER:
                new_width = initial_width + delta_x;

                if (canvas.ctrl_is_pressed || selected_item.size_locked) {
                    new_height = GLib.Math.round (new_width / selected_item.size_ratio);
                }
                break;

            case NobManager.Nob.BOTTOM_RIGHT:
                new_width = initial_width + delta_x;
                new_height = initial_height + delta_y;

                if (canvas.ctrl_is_pressed || selected_item.size_locked) {
                    new_height = GLib.Math.round (new_width / selected_item.size_ratio);
                }
                break;

            case NobManager.Nob.BOTTOM_CENTER:
                new_height = initial_height + delta_y;

                if (canvas.ctrl_is_pressed || selected_item.size_locked) {
                    new_width = GLib.Math.round (new_height * selected_item.size_ratio);
                }
                break;

            case NobManager.Nob.BOTTOM_LEFT:
                new_height = initial_height + delta_y;
                new_width = initial_width - delta_x;
                if (canvas.ctrl_is_pressed || selected_item.size_locked) {
                    new_width = GLib.Math.round (new_height * selected_item.size_ratio);
                }

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;

            case NobManager.Nob.LEFT_CENTER:
                new_width = initial_width - delta_x;
                if (canvas.ctrl_is_pressed || selected_item.size_locked) {
                    new_height = GLib.Math.round (new_width / selected_item.size_ratio);
                }

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;
        }

        // Prevent negative values by forcing a min size of 1px.
        new_width = new_width < MIN_SIZE ? MIN_SIZE : fix_size (new_width);
        new_height = new_height < MIN_SIZE ? MIN_SIZE : fix_size (new_height);

        origin_move_delta_x = new_width == MIN_SIZE ? 0 : fix_size (origin_move_delta_x);
        origin_move_delta_y = new_height == MIN_SIZE ? 0 : fix_size (origin_move_delta_y);

        //  debug ("Y: %f - H: %f", origin_move_delta_y, new_height);

        delta_x_accumulator += origin_move_delta_x;
        delta_y_accumulator += origin_move_delta_y;

        // If the origin changed, update the Matrix coordinates instead of the size.
        if (origin_move_delta_x > 0 || origin_move_delta_y > 0) {

        } else {
            set_size (selected_item, new_width, new_height);
        }

        // selected_item.move (
        //     origin_move_delta_x,
        //     origin_move_delta_y,
        //     delta_x_accumulator,
        //     delta_y_accumulator
        // );

        // set_size (selected_item, new_width, new_height);
    }

    public static void rotate_from_event (
        CanvasItem item,
        double x,
        double y,
        double initial_x,
        double initial_y
    ) {
        var canvas = item.canvas as Akira.Lib.Canvas;
        canvas.convert_to_item_space (item, ref x, ref y);

        var initial_width = item.get_coords ("width");
        var initial_height = item.get_coords ("height");

        var center_x = initial_width / 2;
        var center_y = initial_height / 2;
        var do_rotation = true;
        double rotation_amount = 0;

        var start_radians = GLib.Math.atan2 (
            center_y - initial_y,
            initial_x - center_x
        );

        double current_x, current_y, current_scale, current_rotation;
        item.get_simple_transform (out current_x, out current_y, out current_scale, out current_rotation);
        var radians = GLib.Math.atan2 (center_y - y, x - center_x);

        radians = start_radians - radians;
        var rotation = radians * (180 / Math.PI) + prev_rotation_difference;

        initial_x = x;
        initial_y = y;

        if (canvas.ctrl_is_pressed) {
            do_rotation = false;
        }

        if (canvas.ctrl_is_pressed && rotation.abs () > ROTATION_FIXED_STEP) {
            do_rotation = true;

            // The rotation amount needs to take into consideration
            // the current rotation in order to anchor the item to truly
            // "fixed" rotation step instead of simply adding ROTATION_FIXED_STEP
            // to the current rotation, which might lead to a situation in which you
            // cannot "reset" item rotation to rounded values (0, 90, 180, ...) without
            // manually resetting the rotation input field in the properties panel
            var current_rotation_int = ((int) GLib.Math.round (current_rotation));

            rotation_amount = ROTATION_FIXED_STEP;

            // Strange glitch: when current_rotation == 30.0, the fmod
            // function does not work properly.
            // 30.00000 % 15.00000 != 0 => rotation_amount becomes 0.
            // That's why here is used the int representation of current_rotation
            if (current_rotation_int % ROTATION_FIXED_STEP != 0) {
                rotation_amount -= GLib.Math.fmod (current_rotation, ROTATION_FIXED_STEP);
            }

            var prev_rotation = rotation;
            rotation = rotation > 0 ? rotation_amount : -rotation_amount;
            prev_rotation_difference = prev_rotation - rotation;
        }

        if (do_rotation) {
            canvas.convert_from_item_space (item, ref initial_x, ref initial_y);
            // Round rotation in order to avoid sub degree issue
            rotation = GLib.Math.round (rotation);
            // Cap new_rotation to the [0, 360] range
            var new_rotation = GLib.Math.fmod (item.rotation + rotation, 360);
            set_rotation (item, new_rotation);
            canvas.convert_to_item_space (item, ref initial_x, ref initial_y);
        }

        // Reset rotation to prevent infinite rotation loops.
        prev_rotation_difference = 0.0;
    }

    public static void set_size (Goo.CanvasItem item, double width, double height) {
        if (width != -1) {
            item.set ("width", width);
        }

        if (height != -1) {
            item.set ("height", height);
        }
    }

    public static void set_rotation (CanvasItem item, double rotation) {
        var center_x = item.get_coords ("width") / 2;
        var center_y = item.get_coords ("height") / 2;

        var actual_rotation = rotation - item.rotation;

        item.rotate (actual_rotation, center_x, center_y);

        item.rotation += actual_rotation;
    }

    public static void flip_item (CanvasItem item, double sx, double sy) {
        double x, y, width, height;
        item.get ("x", out x, "y", out y, "width", out width, "height", out height);

        var center_x = x + width / 2;
        var center_y = y + height / 2;

        //  if (item.artboard != null) {
        //      var transform = Cairo.Matrix.identity ();
        //      item.artboard.get_transform (out transform);
        //      transform = item.compute_transform (transform);
        //      double radians = item.rotation * (Math.PI / 180);

        //      transform.translate (center_x, center_y);
        //      transform.rotate (-radians);
        //      transform.scale (sx, sy);
        //      transform.rotate (radians);
        //      transform.translate (-center_x, -center_y);

        //      item.set_transform (transform);
        //      return;
        //  }

        var transform = item.get_real_transform ();
        double radians = item.rotation * (Math.PI / 180);

        transform.translate (center_x, center_y);
        transform.rotate (-radians);
        transform.scale (sx, sy);
        transform.rotate (radians);
        transform.translate (-center_x, -center_y);

        //  debug ("X: %f - Y: %f - R: %f", center_x, center_y, radians);

        item.set_transform (transform);
    }

    public static double fix_size (double size) {
        return GLib.Math.round (size);
    }

    public static double deg_to_rad (double deg) {
        return deg * Math.PI / 180.0;
    }
}
