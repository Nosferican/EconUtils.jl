using Documenter, EconUtils

makedocs(
    format = :html,
    sitename = "EconUtils.jl",
    pages = [
        "index.md",
        "GettingStarted.md",
        "API.md",
        "Examples.md",
        "References.md"
    ]
)

deploydocs(
    deps = Deps.pip("pygments", "mkdocs", "python-markdown-math"),
    repo = "github.com/JuliaEconometrics/EconUtils.jl.git",
    julia  = "0.7.0-DEV.2279"
)
