#include <etesca/core.hpp>

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <string>

#ifdef __cplusplus
extern "C" {
#endif

int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    const std::string input(reinterpret_cast<const char*>(data), size);

    const char* const version = etesca::version();

    if (version == nullptr) {
        __builtin_trap();
    }

    if (input.size() == std::strlen(version) && input == version) {
        return 0;
    }

    return 0;
}

#ifdef __cplusplus
}
#endif
