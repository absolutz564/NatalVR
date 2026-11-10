using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

// Brilhos cintilantes na neve: pontinhos espalhados sobre as superfícies voltadas para cima
// perto do caminho do trenó. Usa o shader Natal/GlowHalo com pisca forte, num único mesh (1 draw call).
// As posições são calculadas no Editor e salvas na cena.
[ExecuteAlways]
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class SnowSparkles : MonoBehaviour
{
    public Transform searchRoot;
    [Tooltip("Só espalha em renderers que usam este material (a neve)")]
    public Material snowMaterial;
    [Tooltip("Pontos do caminho (pega de um LightProbeGroup)")]
    public LightProbeGroup pathProbes;
    public float maxDistanceFromPath = 18f;
    [Tooltip("Brilhos por metro quadrado")]
    public float density = 0.6f;
    [Range(0, 1)] public float minUpFacing = 0.6f;
    public Vector2 sizeRange = new Vector2(0.025f, 0.06f);
    public int maxSparkles = 20000;
    public int seed = 11;
    public bool rebuild;

    [SerializeField, HideInInspector] List<Vector3> positions = new List<Vector3>();
    [SerializeField, HideInInspector] List<float> sizes = new List<float>();

    Mesh mesh;

    void OnEnable() => BuildMesh();

    void OnDisable()
    {
        if (mesh == null) return;
        if (Application.isPlaying) Destroy(mesh); else DestroyImmediate(mesh);
    }

#if UNITY_EDITOR
    void OnValidate()
    {
        if (!rebuild) return;
        rebuild = false;
        UnityEditor.EditorApplication.delayCall += () => { if (this != null) Rebuild(); };
    }

    public void Rebuild()
    {
        positions.Clear();
        sizes.Clear();
        if (searchRoot == null || pathProbes == null) { BuildMesh(); return; }

        var path = new List<Vector3>();
        var probes = pathProbes.probePositions;
        for (int i = 0; i + 10 < probes.Length; i += 11) path.Add(probes[i]);

        var rng = new System.Random(seed);
        var verts = new List<Vector3>();
        var tris = new List<int>();
        float maxD2 = maxDistanceFromPath * maxDistanceFromPath;
        foreach (var r in searchRoot.GetComponentsInChildren<MeshRenderer>(true))
        {
            var mf = r.GetComponent<MeshFilter>();
            if (mf == null || mf.sharedMesh == null) continue;
            var mats = r.sharedMaterials;
            var m = mf.sharedMesh;
            m.GetVertices(verts);
            for (int sm = 0; sm < m.subMeshCount && sm < mats.Length; sm++)
            {
                if (mats[sm] != snowMaterial) continue;
                m.GetTriangles(tris, sm);
                for (int t = 0; t < tris.Count; t += 3)
                {
                    var a = r.transform.TransformPoint(verts[tris[t]]);
                    var b = r.transform.TransformPoint(verts[tris[t + 1]]);
                    var c = r.transform.TransformPoint(verts[tris[t + 2]]);
                    var cross = Vector3.Cross(b - a, c - a);
                    float area = cross.magnitude * 0.5f;
                    if (area < 1e-4f) continue;
                    var n = cross.normalized;
                    if (n.y < minUpFacing) continue;
                    var center = (a + b + c) / 3f;
                    bool near = false;
                    foreach (var p in path)
                    {
                        var d = p - center; d.y = 0;
                        if (d.sqrMagnitude < maxD2) { near = true; break; }
                    }
                    if (!near) continue;
                    float expected = area * density;
                    int count = (int)expected + (rng.NextDouble() < expected - (int)expected ? 1 : 0);
                    for (int k = 0; k < count; k++)
                    {
                        float u = (float)rng.NextDouble(), v = (float)rng.NextDouble();
                        if (u + v > 1) { u = 1 - u; v = 1 - v; }
                        var pos = a + (b - a) * u + (c - a) * v + n * 0.03f;
                        positions.Add(transform.InverseTransformPoint(pos));
                        sizes.Add(Mathf.Lerp(sizeRange.x, sizeRange.y, (float)rng.NextDouble()));
                        if (positions.Count >= maxSparkles) break;
                    }
                    if (positions.Count >= maxSparkles) break;
                }
            }
        }
        BuildMesh();
        UnityEditor.EditorUtility.SetDirty(this);
    }
#endif

    void BuildMesh()
    {
        if (mesh == null) mesh = new Mesh { name = "SnowSparkles", hideFlags = HideFlags.DontSave };
        mesh.Clear();
        int n = positions.Count;
        var v = new Vector3[n * 4];
        var uv0 = new Vector2[n * 4];
        var uv1 = new Vector2[n * 4];
        var col = new Color[n * 4];
        var tri = new int[n * 6];
        Vector2[] c = { new Vector2(-1, -1), new Vector2(1, -1), new Vector2(1, 1), new Vector2(-1, 1) };
        var rng = new System.Random(seed + 3);
        for (int i = 0; i < n; i++)
        {
            float ph = (float)rng.NextDouble();
            var tint = Color.Lerp(new Color(0.8f, 0.9f, 1f), Color.white, (float)rng.NextDouble());
            for (int k = 0; k < 4; k++)
            {
                v[i * 4 + k] = positions[i];
                uv0[i * 4 + k] = c[k];
                uv1[i * 4 + k] = new Vector2(i < sizes.Count ? sizes[i] : 0.04f, ph);
                col[i * 4 + k] = tint;
            }
            tri[i * 6] = i * 4; tri[i * 6 + 1] = i * 4 + 1; tri[i * 6 + 2] = i * 4 + 2;
            tri[i * 6 + 3] = i * 4; tri[i * 6 + 4] = i * 4 + 2; tri[i * 6 + 5] = i * 4 + 3;
        }
        mesh.indexFormat = n * 4 > 65000 ? IndexFormat.UInt32 : IndexFormat.UInt16;
        mesh.vertices = v;
        mesh.SetUVs(0, uv0);
        mesh.SetUVs(1, uv1);
        mesh.colors = col;
        mesh.triangles = tri;
        mesh.RecalculateBounds();
        var bb = mesh.bounds; bb.Expand(1f); mesh.bounds = bb;
        GetComponent<MeshFilter>().sharedMesh = mesh;
        var mr = GetComponent<MeshRenderer>();
        mr.shadowCastingMode = ShadowCastingMode.Off;
        mr.receiveShadows = false;
        mr.lightProbeUsage = LightProbeUsage.Off;
        mr.reflectionProbeUsage = ReflectionProbeUsage.Off;
    }
}
