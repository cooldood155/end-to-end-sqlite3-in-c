#include <etesca/core.hpp>

#ifndef ETESCA_VERSION_STRING
#  error "Etesca's version string is not set?"
#endif

namespace etesca {

const char* version() noexcept {
    return ETESCA_VERSION_STRING;
}

} // namespace etesca
