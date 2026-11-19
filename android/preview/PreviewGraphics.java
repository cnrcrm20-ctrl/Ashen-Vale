package com.godot.game;

import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;
import java.util.ArrayList;
import java.util.List;

/** Choose the view and native driver together, not after constructing a Vulkan Surface. */
final class PreviewGraphics {
    private static Boolean vulkan;
    private static native boolean hasGraphicsDevice();

    private static synchronized boolean usableVulkan(Context context) {
        if (vulkan != null) return vulkan;
        vulkan = false;
        if (Build.VERSION.SDK_INT >= 24 && context.getPackageManager().hasSystemFeature(
                PackageManager.FEATURE_VULKAN_HARDWARE_VERSION, 0x400003)) {
            try {
                System.loadLibrary("ashen_gpu");
                vulkan = hasGraphicsDevice();
            } catch (UnsatisfiedLinkError unavailable) {
                // Vulkan itself is optional. Leave the package's GLES path usable.
                vulkan = false;
            }
        }
        Log.i("godot", "AV_GRAPHICS startup=" + (vulkan ? "vulkan-mobile" : "gles3"));
        return vulkan;
    }

    static List<String> commandLine(Context context, List<String> original) {
        List<String> args = new ArrayList<>(original);
        if (!args.contains("--rendering-method") && !args.contains("--rendering-driver")
                && !usableVulkan(context)) {
            args.add("--rendering-method"); args.add("gl_compatibility");
            args.add("--rendering-driver"); args.add("opengl3");
        }
        return args;
    }
}
