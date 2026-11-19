/* Pick a usable graphics view before Godot binds an Android Surface. No device
 * identifiers, analytics, files or permissions. This library is optional. */
#include <jni.h>
#include <vulkan/vulkan.h>

static int usable(VkPhysicalDevice device) {
    VkPhysicalDeviceFeatures features;
    vkGetPhysicalDeviceFeatures(device, &features);
    if (!features.textureCompressionETC2) return 0; /* shipped mobile textures */

    VkQueueFamilyProperties families[32];
    uint32_t count = 32;
    vkGetPhysicalDeviceQueueFamilyProperties(device, &count, families);
    for (uint32_t i = 0; i < count; ++i) {
        if (families[i].queueCount && (families[i].queueFlags & VK_QUEUE_GRAPHICS_BIT)) return 1;
    }
    return 0;
}

JNIEXPORT jboolean JNICALL
Java_com_godot_game_PreviewGraphics_hasGraphicsDevice(JNIEnv *env, jclass cls) {
    (void)env; (void)cls;
    const char *extensions[] = {"VK_KHR_surface", "VK_KHR_android_surface"};
    VkApplicationInfo app = {.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
                             .pApplicationName = "Ashen Vale", .apiVersion = VK_API_VERSION_1_0};
    VkInstanceCreateInfo info = {.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
                                 .pApplicationInfo = &app, .enabledExtensionCount = 2,
                                 .ppEnabledExtensionNames = extensions};
    VkInstance instance = VK_NULL_HANDLE;
    if (vkCreateInstance(&info, NULL, &instance) != VK_SUCCESS) return JNI_FALSE;
    VkPhysicalDevice devices[16];
    uint32_t count = 16;
    VkResult result = vkEnumeratePhysicalDevices(instance, &count, devices);
    jboolean ready = JNI_FALSE;
    if (result == VK_SUCCESS || result == VK_INCOMPLETE) {
        /* Godot may choose among these GPUs. Do not select a Vulkan view when
         * the advertised list is empty or a candidate cannot read our format. */
        ready = count ? JNI_TRUE : JNI_FALSE;
        for (uint32_t i = 0; i < count && ready; ++i) ready = usable(devices[i]) ? JNI_TRUE : JNI_FALSE;
    }
    vkDestroyInstance(instance, NULL);
    return ready;
}
