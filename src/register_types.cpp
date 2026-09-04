#include "register_types.h"

#include "player.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

//wait for godot initialization
void godot::initialize_player_module(godot::ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	GDREGISTER_CLASS(Player);
}

//wait for godot initialization
void godot::uninitialize_player_module(godot::ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}

extern "C" {
// Initialization.
GDExtensionBool GDE_EXPORT example_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(godot::initialize_player_module);
	init_obj.register_terminator(godot::uninitialize_player_module);
	init_obj.set_minimum_library_initialization_level(godot::MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}