#include <catch2/catch_test_macros.hpp>

#include <etesca/core.hpp>

#include <string_view>

TEST_CASE("etesca reports a version string", "[core]") {
    const std::string_view version{etesca::version()};
    REQUIRE_FALSE(version.empty());
}
