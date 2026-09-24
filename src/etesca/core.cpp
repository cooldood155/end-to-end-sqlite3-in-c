#include <etesca/core.hpp>

#ifndef ETESCA_VERSION_STRING
#  define ETESCA_VERSION_STRING "0.0.0"
#endif

namespace etesca {

const char* version() noexcept {
    return ETESCA_VERSION_STRING;
}

} // namespace etesca
