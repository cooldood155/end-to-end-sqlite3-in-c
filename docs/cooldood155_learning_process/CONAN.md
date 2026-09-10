# Conan2 Documentation

## `conanfile.py`

This is all that Conan requires for managing your C/C++ packages.

Each package is defined as its own class inheriting from the `ConanFile` class,
exposed within the `conan` package namespace.

These *classes* are **package recipes** that are provided to Conan so it can do
the work of generating the package.

```Python
from conan import ConanFile

class EtescaRecipe(Conanfile):
    ...
```

### Recipe Attributes

Each defined package recipe has many possible attributes you can define,
grouped together into different categories.

There are 66 different attributes,
of these attributes only 2 affect the packages resulting package_id:

1. Binary model > `settings`
2. Binary model > `options`

---

Below lists most attribute provided, along with a short description for each.
Each attribute is listed under the category it belongs to:

- [Package reference](https://docs.conan.io/2/reference/conanfile/attributes.html#package-reference):
  Recipe attributes that can define the main `pkg/version@user/channel` package
  reference. This is the full naming format used to uniquely identify a
  package.

  - `name`: The unique name of the package.
  - `version`: The specific release number of the package (e.g., `1.8.2`).
  - `user`: A namespace for the package, **optional**.
  - `channel`: Lifecycle stage or maturity level (e.g., `stable`, `testing`,
    `dev`, etc.), **optional**.

- [Metadata](https://docs.conan.io/2/reference/conanfile/attributes.html#metadata):
  > **Optional** metadata, like license, description, author, etc. Not
  > necessary for most cases, but can be useful to have.

  - `description`: The description of the package, and any information that
    might be useful for the consumer.
  - `license`: License of the **target** source code and binaries, i.e. the
    code that is being packaged, **not** the `conanfile.py` itself.
  - `author`: Main maintainer/responsible for the package, any format.
  - `topics`: **Tags** to group related packages and describe the code.
  - `homepage`: The **home web page** of the library being packaged.
  - `url`: URL of the **package repository**, *not necessarily** the original
    source code.

- [Requirements](https://docs.conan.io/2/reference/conanfile/attributes.html#requirements):
  Attribute form of the dependencies simple declarations, like `requries`,
  `tool_requires`. If a package requires any form of dynamic dependency
  resolution functionality or advanced define requirements, then it must use
  the method form of the [`requires`](https://docs.conan.io/2/reference/conanfile/methods/requirements.html)
  and/or [`tool_requires`](https://docs.conan.io/2/reference/conanfile/methods/build_requirements.html#build-requirements)
  and/or [`test_requires`](https://docs.conan.io/2/reference/conanfile/methods/build_requirements.html#build-requirements) attributes.

  - `requires`: List or typle of strings for regular dependencies in the host
    context, like a library.
  - `tool_requires`: List or tuple of strings for dependencies. Represents a
    build tool like "cmake".
  - `test_requires`: Lists or tuple of strings for dependencies in the **host
    context only.** Represents a test tool like "ctest".
  - `python_requires`: This class attribute can define a dependency to another
    Conan recipe and reuse its code, **imported `conanfile.py`'s**.
  - `python_requires_extend`: This class attribute defines one or more classes
    that will be injected at runtime as base classes of the recipe class, the
    **classes from imported `conanfile.py`'s** to inject as a base class.

- [Sources](https://docs.conan.io/2/reference/conanfile/attributes.html#sources):
  Specifies local source and companion files that must be bundled alongside the
  recipe when stored in Conan's cache.

  - `exports`: *File names* or [fnmatch](https://docs.python.org/3/library/fnmatch.html)
    patterns that should be exported and stored side by side with the
    *`conanfile.py`* file to **make the recipe work**.
  - `exports_sources`: List or tuple of strings with file names of
    [fnmatch](https://docs.python.org/3/library/fnmatch.html) patterns that
    should be exported and will be available **to generate the package**.
  - `conan_data`: Read only attribute with a dictionary with the keys and
    values provided in a [conandata.yml](https://docs.conan.io/2/tutorial/creating_packages/handle_sources_in_packages.html#creating-packages-handle-sources-in-packages-conandata)
    file format placed next to the `conanfile.py`.
  - `source_buildenv`: Boolean to opt-into injecting the [VirtualBuildEvn](https://docs.conan.io/2/reference/tools/env/virtualbuildenv.html#conan-tools-env-virtualbuildenv)
    generated environment while running the *source()* method.

- [Binary model](https://docs.conan.io/2/reference/conanfile/attributes.html#binary-model)
  **Important attributes** that define the package binary model, which
  settings, options, package type, etc. affect the final packaged binaries.

  - `package_type`: Optional, but very **strongly recommended**. Declaring the
    `package_type` will help Conan choose the best default `package_id_mode`
    for each dependency and which information from the dependencies should be
    propagated to the consumers.
  - `settings`: List of strings with the first level settings (from [settings.yml](https://docs.conan.io/2/reference/config_files/settings.html#reference-config-files-settings-yml))
    that the recipe needs for building and possibly effects the `package_id`.
  - `options`: Dictionary with traits that affects only the current recipe,
    where the key is the option name and the value is a list of possible values
    the option can be.
  - `default_options`: Defines the default values for the options, both for the
    current recipe and for any packages it depends on (upstream requirements).
  - `default_build_options`: Defines the default values for the options in the
    build context and is typically used for defining options for
    `tool_requires`.
  - `options_description`: An optional attribute that can be defined in the
    form of a dictionary where the key is the option name and the value is a
    description of the option in text format.
  - `languages`: **Experimental, subject to breaking changes.** From Conan 2.4,
    the `conanfile.py` recipe attribute `languages` can be used to define the
    programming languages involved in this package.
  - `info`: Object used exlusively in the `package_id()` method.
  - `package_id_{embed,non_embed,python,unknown}_mode, build_mode`: Class
    attributes that can be defined in recipes to define the effect they have on
    their consumers' `package_id`, when they are consumed as `requires`.
  - `package_id_abi_options`: You may want to make the value of a given option
    influence the `package_id` of the binaries consuming this package.
  - `context`: **Experimental, subject to breaking changes.** Contains either
    the "build" or "host" value to represent the context where the **current
    package instance** is being evaluated.

- [Build](https://docs.conan.io/2/reference/conanfile/attributes.html#build)

  - `generators`: List or tuple of strings with names of generators.
  - `build_policy`: Controls when the current package is build during a
    `conan install`.
  - `win_bash`: When `True` it enables the new run in a subsystem bash in
    Windows mechanism.
  - `win_bash_run`: When `True` it enables running commands in the `"run"`
    scope, to run them inside a bash shell.

- [Folders and layout](https://docs.conan.io/2/reference/conanfile/attributes.html#folders-and-layout)

- [Layout](https://docs.conan.io/2/reference/conanfile/attributes.html#layout)

- [Package information for consumers](https://docs.conan.io/2/reference/conanfile/attributes.html#package-information-for-consumers)

- [Other](https://docs.conan.io/2/reference/conanfile/attributes.html#other)

---

A lot of the provided attributes have method alternatives that can be used for
finer grained control and specific scenarios when needed.

**Example:**

```Python
from conan import ConanFile

class EtescaRecipe(ConanFile):
  name = "etesca"
  package_type = "shared-library"
  settings = "os", "arch", "compiler", "build_type"

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

    ...
```

### Recipe Methods

Methods that can be defined in recipes to customize the package creation &
consumption processes. There are 25 different methods all listed here: <https://docs.conan.io/2/reference/conanfile/methods.html>

**Example:**

```Python
from conan import ConanFile

class EtescaRecipe(ConanFile):
  name = "etesca"
  package_type = "shared-library"
  settings = "os", "arch", "compiler", "build_type"

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

  def build(self):
    # Build instructions to build a package from source
    ...

  def build_requirements(self):
    # defines tool_requires (build time deps) and test_requires (test deps)
    ...

  def configure(self):
    # Configuration of settings and options in the recipe for use in methods
    ...

  def config_options(self):
    # Configure/constrain the available options in a package before assigment
    ...

  def generate(self):
    # Prepare the build, generating the necessary files.
    ...

  def layout(self):
    # Sets up standard directories and enables CMake presets
    ...

  def package(self):
    # Copy files from source_folder & temporary build_folder to package_folder
    ...

  def package_info(self):
    # Defines information to the package consumer
    ...

  def set_version(self):
    # Dynamically define the version attribute (from CMakeLists.txt below)
    ...
```

### CMake Integration Tools/Helpers

Package recipes relying on CMake *should* include helpers from the `cmake.py`
module from within the `conan.tools` package namespace. This module groups
together tools, file generators, and helpers for integrating CMake
([more info](https://docs.conan.io/2/reference/tools/cmake/cmake.html)).

`conan.tools.cmake`, explained above, exposes the following tools/components:

- [`CMake`](https://docs.conan.io/2/reference/tools/cmake/cmake.html): The main
  build helper wrapper used to drive the configurations, building, testing, and
  installing steps (e.g., calling `cmake.configure()` and `cmake.build()`).

- [`CMakeToolchain`](https://docs.conan.io/2/reference/tools/cmake/cmaketoolchain.html):
  The toolchain generator responsible for translating *your* Conan profile,
  architecture, and compiler settings into a `conan_toolchain.cmake` file and
  `CMakePresets.json`.

- [`CMakeDeps`](https://docs.conan.io/2/reference/tools/cmake/cmakedeps.html):
  The dependency generator that produces standard `xxx-config.cmake` files for
  all of the required packages, allowing you to use native CMake
  `find_package()` calls.

- [`CMakeConfigDeps`](https://docs.conan.io/2/reference/tools/cmake/cmakeconfigdeps.html):
  A modern, optimized alternative to `CMakeDeps` introduced in Conan2 to handle advanced
  multi-context target generations (like distinguishing between "host" and"build"
  contexts).

- [`cmake_layout`](https://docs.conan.io/2/reference/tools/cmake/cmake_layout.html):
  A structrual predifined layout function that automatically defines standard
  subdirectories for sources and build configurations matching typical CMake
  configuration workflows.

```Python
from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout

class EtescaRecipe(ConanFile):
    name = "etesca"
    package_type = 
```

### File and Directory Processing Tools/Helpers

The `conan.tools.files` module is a collection of utilities designed to
manipulate files and directories safely inside recipe methods like `source()`,
`build()`, and `package()`.

Replaces older, deprecated Conan 1.X file tools and **ensures** your recipe
is cross-platform.

The full list of publically exposed utilities the module provies can be found
here <https://docs.conan.io/2/reference/tools/files.html>

### *Semi-Full* Example

**Example:**

```Python
from conan import ConanFile
from conan.tool.cmake import cmake_layout, CMake
from conan.tool.files import load

class EtescaRecipe(ConanFile):
  name = "etesca"
  package_type = "shared-library"
  settings = "os", "arch", "compiler", "build_type"

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

  def build(self):
    # Build instructions to build a package from source
    cmake = CMake(self)
    cmake.configure()
    cmake.build()
    cmake.ctest()

  def build_requirements(self):
    # defines tool_requires (build time deps) and test_requires (test deps)
    self.test_requires("catch2/[>=3.7.1]")
    self.tool_requires("cmake/[>=3.30]")

  def configure(self):
    # Configuration of settings and options in the recipe for use in methods
    if self.options.shared:
      self.options.rm_safe("fPIC")

  def config_options(self):
    # Configure/constrain the available options in a package before assigment
    if self.settings.os == "Windows":
      del self.options.fPIC

  def generate(self):
    # Prepare the build, generating the necessary files.
    ...

  def layout(self):
    # Sets up standard directories and enables CMake presets
    cmake_layout(self)

  def package(self):
    # Copy files from source_folder & temporary build_folder to package_folder
    CMake(self).install()

  def package_info(self):
    # Defines information to the package consumer
    ...

  def set_version(self):
    # Dynamically define the version attribute (from CMakeLists.txt below)
    cmake_path = path.join(self.recipe_folder, "CMakeLists.txt")
    content = load(self, cmake_path)

    match = serach(r"projects\s*\([^)]*VERSION\s+((?:\d+\.){3})", content,
                   IGNORECASE)
    if match:
      self.version = match.group(1)
    else:
      raise LookupError("Could not find top-level CMake project version.")
```
