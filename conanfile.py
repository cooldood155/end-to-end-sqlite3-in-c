# pyright: reportAttributeAccessIssue=false, reportOptionalCall=false, reportArgumentType=false, reportCallIssue=false

from os import path
from re import search, IGNORECASE
from conan import ConanFile
from conan.tools.cmake import cmake_layout, CMake, CMakeDeps, CMakeToolchain
from conan.tools.files import save, load

class EtescaRecipe(ConanFile):
  name = "etesca"
  package_type = "shared-library"
  settings = "os", "arch", "compiler", "build_type"

  description = "Install and generate the required CMake configuration files"
  license = "MIT"
  author = "Evan R. Reumann (evanrileyreumann@gmail.com)"
  url = "https://github.com/cooldood155/end-to-end-sqlite3-in-c"

  options = {
    "shared": [True, False],
    "fPIC": [True, False]
  }
  default_options = {
    "shared": False,
    "fPIC": True
  }

  exports_sources = (
    "CMakeLists.txt",
    "cmake/*",
    "include/*",
    "src/*",
    "apps/*",
    "tools/*",
    "tests/*")

  def set_version(self):
    cmake_path = path.join(self.recipe_folder, "CMakeLists.txt")
    content = load(self, cmake_path)

    match = search(r"projects\s*\([^)]*VERSION\s+((?:\d+\.){3})", content,
                   IGNORECASE)
    if match:
      self.version = match.group(1)
    else:
      raise LookupError("Could not find top-level CMake project version.")

  def package_info(self):
    self.cpp_info.libs = ["etesca"]
    self.cpp_info.set_property("cmake_file_name", "etesca")
    self.cpp_info.set_property("cmake_target_name", "etesca::etesca")

  def generate(self):
    deps = CMakeDeps(self)
    deps.generate()

    tc = CMakeToolchain(self)
    tc.user_presets_path = False

    build_tests = not self.conf.get(
      "tools.build:skip_tests", default=False, check_type=bool)

    tc.variables["ETESCA_BUILD_TESTS"] = build_tests
    tc.cache_variables["ETESCA_BUILD_TESTS"] = build_tests

    tc.generate()

    save(self, path.join(self.generators_folder, "etesa_intent.cmake"),
      "set(ETESCA_TOOLCHAIN_SHARED {})\n".format(
        "ON" if self.options.get_safe("shared") else "OFF"))

  def build_requirements(self):
    self.test_requires("catch2/[>=3.7.1]")
    self.tool_requires("cmake/[>=3.30]")

  def build(self):
    cmake = CMake(self)
    cmake.configure()
    cmake.build()
    cmake.ctest()

  def config_options(self):
    if self.settings.os == "Windows":
      del self.options.fPIC

  def configure(self):
    if self.options.shared:
      self.options.rm_safe("fPIC")

  def layout(self):
    cmake_layout(self)

  def package(self):
    CMake(self).install()
