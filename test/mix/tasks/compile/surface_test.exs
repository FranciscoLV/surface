defmodule Mix.Tasks.Compile.SurfaceTest do
  use ExUnit.Case, async: false

  import Mix.Tasks.Compile.Surface

  @hooks_output_dir "tmp/_hooks"
  @hooks_abs_output_dir Path.join(File.cwd!(), @hooks_output_dir)
  @test_components_dir Path.join(File.cwd!(), "test/support/mix/tasks/compile/surface_test")

  setup_all do
    Mix.shell(Mix.Shell.Process)

    conf_before = Application.get_env(:surface, :compiler, [])
    Application.put_env(:surface, :compiler, hooks_output_dir: @hooks_output_dir)

    on_exit(fn ->
      Application.put_env(:surface, :compiler, conf_before)
    end)

    :ok
  end

  setup do
    if File.exists?(@hooks_abs_output_dir) do
      File.rm_rf!(@hooks_abs_output_dir)
    end

    on_exit(fn ->
      File.rm_rf!(@hooks_abs_output_dir)
    end)

    :ok
  end

  test "copy hooks files to output dir" do
    refute File.exists?(@hooks_abs_output_dir)

    run([])

    # FakeButton

    src_hooks_file = Path.join(@test_components_dir, "fake_button.hooks.js")

    dest_hooks_file =
      Path.join(@hooks_abs_output_dir, "Mix.Tasks.Compile.SurfaceTest.FakeButton.hooks.js")

    assert File.read!(src_hooks_file) == File.read!(dest_hooks_file)

    # FakeLink

    src_hooks_file = Path.join(@test_components_dir, "fake_link.hooks.js")

    dest_hooks_file =
      Path.join(@hooks_abs_output_dir, "Mix.Tasks.Compile.SurfaceTest.FakeLink.hooks.js")

    assert File.read!(src_hooks_file) == File.read!(dest_hooks_file)
  end

  test "generate index.js file for hooks" do
    refute File.exists?(@hooks_abs_output_dir)

    run([])

    index_file = Path.join(@hooks_abs_output_dir, "index.js")

    assert File.read!(index_file) == """
           /* This file was generated by the Surface compiler */

           function ns(hooks, nameSpace) {
             const updatedHooks = {}
             Object.keys(hooks).map(function(key) {
               updatedHooks[`${nameSpace}#${key}`] = hooks[key]
             })
             return updatedHooks
           }

           import * as c1 from "./Mix.Tasks.Compile.SurfaceTest.FakeButton.hooks"
           import * as c2 from "./Mix.Tasks.Compile.SurfaceTest.FakeLink.hooks"

           let hooks = Object.assign(
             ns(c1, "Mix.Tasks.Compile.SurfaceTest.FakeButton"),
             ns(c2, "Mix.Tasks.Compile.SurfaceTest.FakeLink")
           )

           export default hooks
           """
  end

  test "generate index.js with empty object if there's no hooks available" do
    refute File.exists?(@hooks_abs_output_dir)

    generate_files({[], []})

    index_file = Path.join(@hooks_abs_output_dir, "index.js")

    assert File.read!(index_file) == """
           /* This file was generated by the Surface compiler */

           export default {}
           """
  end

  test "delete unused hooks files from output dir" do
    refute File.exists?(@hooks_abs_output_dir)

    File.mkdir_p!(@hooks_abs_output_dir)

    unused_file = Path.join(@hooks_abs_output_dir, "Unused.hooks.js")
    File.touch!(unused_file)

    assert File.exists?(unused_file)

    run([])

    refute File.exists?(unused_file)
  end
end
