using Microsoft.AspNetCore.Mvc;

namespace KianaBH.SdkServer.Handlers.Sdk;

[ApiController]
public class AssetController : ControllerBase
{
    private readonly Dictionary<string, string> _assetPaths = new()
    {
        { "data/build.status", "DataBuild.status" },    
        { "event/build.status", "EventBuild.status" },
        { "data/editor_compressed/DataVersion.unity3d", "DataVersion.unity3d" },
        { "event/editor_compressed/ResourceVersion.unity3d", "EventResourceVersion.unity3d" },
        { "ai/editor_compressed/ResourceVersion.unity3d", "AiResourceVersion.unity3d" },
        { "Audio/Windows/8_4/761708/manifest_3939265069fb7c94200e36cefa8e101e.m", "manifest_3939265069fb7c94200e36cefa8e101e.m" },
        { "StreamingAsb/8_4_0/pc/HD/asb/BlockMeta_8_4_0d290dd93e3ffe974a64e0c1c2b75e1d.xmf", "BlockMeta_8_4_0d290dd93e3ffe974a64e0c1c2b75e1d.xmf" },
        { "Video/VideoEncrypt/product_os_video_encrypt_339a1e36978910e055e49fd8945109e9", "product_os_video_encrypt_339a1e36978910e055e49fd8945109e9" },
    };

    private readonly DirectoryInfo _assetsDirectory = new(Path.Combine(Directory.GetCurrentDirectory(), "Assets"));

    private string GetAssetPath(string assetName)
    {
        return Path.Combine(_assetsDirectory.FullName, _assetPaths[assetName]);
    }

    [HttpGet("/asset_bundle/overseas01/1.1/{**lastPartOfPath}")]
    public IActionResult GetAsset(string lastPartOfPath)
    {
        if (_assetPaths.TryGetValue(lastPartOfPath, out var mappedPath))
        {
            var filePath = Path.Combine(_assetsDirectory.FullName, mappedPath);
            return File(System.IO.File.ReadAllBytes(filePath), "application/octet-stream", Path.GetFileName(mappedPath));
        }
        return NotFound($"Asset not found: {lastPartOfPath}");
    }

    [HttpGet("/com.miHoYo.bh3oversea/{**lastPartOfPath}")]
    public IActionResult GetManifestAsset(string lastPartOfPath)
    {
        if (_assetPaths.TryGetValue(lastPartOfPath, out var mappedPath))
        {
            var filePath = Path.Combine(_assetsDirectory.FullName, mappedPath);
            return File(System.IO.File.ReadAllBytes(filePath), "application/octet-stream", Path.GetFileName(mappedPath));
        }
        return NotFound($"Asset not found: {lastPartOfPath}");
    }
}