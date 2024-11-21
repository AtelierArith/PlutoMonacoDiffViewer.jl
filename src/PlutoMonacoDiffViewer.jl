module PlutoMonacoDiffViewer

using Base64: base64encode
using HypertextLiteral: @htl
using PlutoUI: @bind

function simple_comparision_textfield(default_common, default_codeA, default_codeB)
	default_code_common = """
	# common code
	using InteractiveUtils
	"""

	default_codeA = """
	# codeA
	"""

	default_codeB = """
	# codeB
	"""

	ui_common = @bind code_common PlutoUI.TextField((84, 10), default=default_code_common)
	ui_codeA = @bind codeA PlutoUI.TextField((40, 8), default=default_codeA)
	ui_codeB = @bind codeB PlutoUI.TextField((40, 8), default=default_codeB)

	return PlutoUI.ExperimentalLayout.vbox(
		[
			ui_common,
			PlutoUI.ExperimentalLayout.hbox([ui_codeA, Text(" "), ui_codeB])
		]
		
	)
end

function monaco_diffviewer_js(o1::String, o2::String)
	o1buf = IOBuffer()
	o2buf = IOBuffer()
	write(o1buf, o1)
	write(o2buf, o2)
	b64o1 = base64encode(String(take!(o1buf)))
	b64o2 = base64encode(String(take!(o2buf)))
	
	diffjs = """
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
	diffjs
end

function PlutoMonacoDiffViewer(o1::String, o2::String)
	diffbuf = IOBuffer()
	write(diffbuf, monaco_diffviewer_js(o1,o2))
	b64diff = base64encode(String(take!(diffbuf)))
	b64diff = "data:text/javascript;base64,$(b64diff)"
	return @htl """
	<script src="https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.7/require.js"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.52.0/min/vs/loader.js"></script>
	
	<h2>Monaco Diff Editor Sample</h2>
	<div id="mycontainer" style="width: 1400px; height: 500px; border: 1px solid grey"></div>
	<script type="text/javascript" src="$(b64diff)"></script>
	"""
end

end # module PlutoMonacoDiffViewer
