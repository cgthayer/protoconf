load("@build_stack_rules_proto//:plugin.bzl", "ProtoPluginInfo")
load("@protobuf_py_deps//:requirements.bzl", protobuf_requirements = "all_requirements")
load("@grpc_py_deps//:requirements.bzl", grpc_requirements = "all_requirements")
load(
    "@build_stack_rules_proto//:aspect.bzl",
    "ProtoLibraryAspectNodeInfo",
    "proto_compile_aspect_attrs",
    "proto_compile_aspect_impl",
    "proto_compile_attrs",
    "proto_compile_impl",
)

python_grpclib_compile_aspect = aspect(
    attr_aspects = ["deps"],
    attrs = dict(
        proto_compile_aspect_attrs,
        _plugins = attr.label_list(
            doc = "List of protoc plugins to apply",
            providers = [ProtoPluginInfo],
            default = [
                str(Label("@build_stack_rules_proto//python:python")),
                str(Label("//:grpc_python")),
            ],
        ),
    ),
    provides = [
        "proto_compile",
        ProtoLibraryAspectNodeInfo,
    ],
    implementation = proto_compile_aspect_impl,
)

_rule = rule(
    attrs = dict(
        proto_compile_attrs,
        deps = attr.label_list(
            mandatory = True,
            providers = [
                ProtoInfo,
                "proto_compile",
                ProtoLibraryAspectNodeInfo,
            ],
            aspects = [python_grpclib_compile_aspect],
        ),
    ),
    implementation = proto_compile_impl,
)

def python_grpclib_compile(**kwargs):
    _rule(
        verbose_string = "%s" % kwargs.get("verbose", 0),
        plugin_options_string = ";".join(kwargs.get("plugin_options", [])),
        **kwargs
    )

def python_grpclib_library(**kwargs):
    name = kwargs.get("name")
    deps = kwargs.get("deps")
    visibility = kwargs.get("visibility")

    name_pb = name + "_pb"
    python_grpclib_compile(
        name = name_pb,
        transitive = kwargs.pop("transitive", True),
        transitivity = kwargs.pop("transitivity", {}),
        verbose = kwargs.pop("verbose", 0),
        visibility = visibility,
        deps = deps,
    )

    py_library(
        name = name,
        srcs = [name_pb],
        # This magically adds REPOSITORY_NAME/PACKAGE_NAME/{name_pb} to PYTHONPATH
        imports = [name_pb],
        visibility = visibility,
        deps = depset(protobuf_requirements + grpc_requirements).to_list(),
    )
