### A Pluto.jl notebook ###
# v0.20.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ cd2d791c-a4b8-11ef-2264-0fa0d581f8c0
begin
	using Base64
	using CodeEvaluation
	using BenchmarkTools
end

# ╔═╡ 5dde46e9-4bf4-49bd-9f67-6c5f2489ac3c
begin
	using PlutoUI
	using HypertextLiteral
end

# ╔═╡ 120c528b-3100-4984-9c58-aa4280b7d90a
begin
	using InteractiveUtils
	
	function f(x)
		x > 0 ? x : 0
	end
	
	function g(x)
		x > zero(x) ? x : zero(x)
	end
end

# ╔═╡ 06a6a96f-8da0-4cbf-9cfe-5022d9451cde
# Change styles that make cells be wide
html"""
<style>
main {
margin: 0 auto;
max-width: 2000px;
    padding-left: max(50px, 5%);
    padding-right: max(50px, 5%);
}
</style>
"""

# ╔═╡ 8713d2c3-cf0e-4c45-be06-6ca0ec773d54
function clean_ansi_escape(s)
	# Regular expression pattern to match ANSI escape sequences
	ansi_escape_pattern = r"\e\[[0-9;]*m"
	# Replace ANSI escape sequences with empty strings
	s_clean = replace(s, ansi_escape_pattern => "")
	return s_clean
end

# ╔═╡ d9003dc0-70e6-4732-be7f-274dbbe38ec7
@code_warntype f(1.0)

# ╔═╡ 84c169f7-5c75-461c-8643-a7144323c718
@code_warntype g(1.0)

# ╔═╡ b012c4e0-43a9-40e8-9b4a-e643a4929e89
# this causes type instability
@benchmark f(x) setup=begin
	x = rand()
end samples=1000000

# ╔═╡ 45a8e656-6d6e-45ca-a695-0ea706d24f50
# type stable implementation
@benchmark g(x) setup=begin
	x = rand()
end samples=1000000

# ╔═╡ e60c2e7e-ed7a-4cbe-a537-5ed1381cb10f
begin
	default_code_common = """
	using InteractiveUtils
	
	function codeA(x)
		x > 0 ? x : 0
	end
	
	function codeB(x)
		x > 0 ? x : zero(x)
	end
	"""

	default_codeA = """
	# codeA
	@code_llvm debuginfo=:none codeA(1.0)
	"""

	default_codeB = """
	# codeB
	@code_llvm debuginfo=:none codeB(1.0)
	"""

	ui_common = @bind code_common PlutoUI.TextField((84, 10), default=default_code_common)
	ui_codeA = @bind codeA PlutoUI.TextField((40, 8), default=default_codeA)
	ui_codeB = @bind codeB PlutoUI.TextField((40, 8), default=default_codeB)

	PlutoUI.ExperimentalLayout.vbox(
		[
			ui_common,
			PlutoUI.ExperimentalLayout.hbox([ui_codeA, Text(" "), ui_codeB])
		]
		
	)
end

# ╔═╡ 3040c341-e0d5-4fef-8091-115bee456d12
begin
	sb1 = CodeEvaluation.Sandbox()
	sb2 = CodeEvaluation.Sandbox()

	CodeEvaluation.codeblock!(sb1, code_common)
	r1 = CodeEvaluation.codeblock!(sb1, codeA)
	CodeEvaluation.codeblock!(sb2, code_common)
	r2 = CodeEvaluation.codeblock!(sb2, codeB)

	if isnothing(r1.value)
		o1 = clean_ansi_escape(r1.output)
	else
		o1 = string(r1.value)
	end
	
	if isnothing(r2.value)
		o2 = clean_ansi_escape(r2.output)
	else
		o2 = string(r2.value)
	end
end

# ╔═╡ 4906a5b5-bade-407f-9895-874fbcc02f06
@bind outA PlutoUI.TextField((80, 5), default=o1)

# ╔═╡ b2cad113-37ba-4074-9c81-ddcb1aecbfeb
@bind outB PlutoUI.TextField((80, 5), default=o2)

# ╔═╡ 6edbe069-3c4e-461d-acef-effebfc6b001
function diffjs(o1::String, o2::String)
	o1buf = IOBuffer()
	o2buf = IOBuffer()
	write(o1buf, o1)
	write(o2buf, o2)
	b64o1 = base64encode(String(take!(o1buf)))
	b64o2 = base64encode(String(take!(o2buf)))
	
	diffjstemplate = """
function decodeBase64(base64String) {
    const prefix = "data:text/plain;base64,";
    if (base64String.startsWith(prefix)) {
        base64String = base64String.slice(prefix.length);
    }
    const decodedData = atob(base64String);
    return decodedData;
}

require.config({ paths: { vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.52.0/min/vs' }});

require(['vs/editor/editor.main'], () => {
	var diffEditor = monaco.editor.createDiffEditor(document.getElementById('mycontainer'));
	let originalTxt = decodeBase64("$(b64o1)");
	let modifiedTxt = decodeBase64("$(b64o2)");
	console.log(modifiedTxt)
	diffEditor.setModel({
		original: monaco.editor.createModel(originalTxt, 'julia'),
		modified: monaco.editor.createModel(modifiedTxt, 'julia')
	});
});
"""
	diffjstemplate
end

# ╔═╡ af06ea82-a418-4ca3-b338-11ff638c9b5b
#=
let
	diffbuf = IOBuffer()
	write(diffbuf, diffjs(o1,o2))
	b64diff = base64encode(String(take!(diffbuf)))
	b64diff = "data:text/javascript;base64,$(b64diff)"
	write("diff.js", diffjs(o1,o2))
	@htl """
	<script src="https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.7/require.js"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.52.0/min/vs/loader.js"></script>
	
	<h2>Monaco Diff Editor Sample</h2>
	<div id="mycontainer" style="width: 1400px; height: 500px; border: 1px solid grey"></div>
	$(PlutoUI.LocalResource("diff.js"))
	"""
end
=#

# ╔═╡ 0d28ef65-c075-4053-9fb7-2abafc5c5b8b
let
	diffbuf = IOBuffer()
	write(diffbuf, diffjs(o1,o2))
	b64diff = base64encode(String(take!(diffbuf)))
	b64diff = "data:text/javascript;base64,$(b64diff)"
	@htl """
	<script src="https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.7/require.js"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.52.0/min/vs/loader.js"></script>
	
	<h2>Monaco Diff Editor Sample</h2>
	<div id="mycontainer" style="width: 1400px; height: 500px; border: 1px solid grey"></div>
	<script type="text/javascript" src="$(b64diff)"></script>
	"""
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Base64 = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
CodeEvaluation = "5a076611-96cb-4f02-9d3a-9e309f06f8ff"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
InteractiveUtils = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
BenchmarkTools = "~1.5.0"
CodeEvaluation = "~0.0.1"
HypertextLiteral = "~0.9.5"
PlutoUI = "~0.7.60"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.2"
manifest_format = "2.0"
project_hash = "a586c8f41d68906ccb9115c3279c4280c1d1a32e"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "f1dff6729bc61f4d49e140da1af55dcd1ac97b2f"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.5.0"

[[deps.CodeEvaluation]]
deps = ["IOCapture", "REPL"]
git-tree-sha1 = "d6c697393845c7573b85719b49158ff27ed5adc5"
uuid = "5a076611-96cb-4f02-9d3a-9e309f06f8ff"
version = "0.0.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eba4810d5e6a01f612b948c9fa94f905b49087b0"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.60"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Profile]]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
version = "1.11.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tricks]]
git-tree-sha1 = "7822b97e99a1672bfb1b49b668a6d46d58d8cbcb"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.9"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╠═06a6a96f-8da0-4cbf-9cfe-5022d9451cde
# ╠═cd2d791c-a4b8-11ef-2264-0fa0d581f8c0
# ╠═5dde46e9-4bf4-49bd-9f67-6c5f2489ac3c
# ╠═8713d2c3-cf0e-4c45-be06-6ca0ec773d54
# ╠═120c528b-3100-4984-9c58-aa4280b7d90a
# ╠═d9003dc0-70e6-4732-be7f-274dbbe38ec7
# ╠═84c169f7-5c75-461c-8643-a7144323c718
# ╠═b012c4e0-43a9-40e8-9b4a-e643a4929e89
# ╠═45a8e656-6d6e-45ca-a695-0ea706d24f50
# ╠═e60c2e7e-ed7a-4cbe-a537-5ed1381cb10f
# ╠═3040c341-e0d5-4fef-8091-115bee456d12
# ╠═4906a5b5-bade-407f-9895-874fbcc02f06
# ╠═b2cad113-37ba-4074-9c81-ddcb1aecbfeb
# ╠═6edbe069-3c4e-461d-acef-effebfc6b001
# ╠═af06ea82-a418-4ca3-b338-11ff638c9b5b
# ╠═0d28ef65-c075-4053-9fb7-2abafc5c5b8b
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
