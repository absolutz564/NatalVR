using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

// Pisca-pisca em espiral nos pinheiros. Todas as lâmpadas ficam num único mesh de billboards
// (shader Natal/GlowHalo com pisca), então custa 1 draw call. As posições são calculadas no Editor
// a partir do formato de cone de cada pinheiro e salvas na cena.
[ExecuteAlways]
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class TreeLights : MonoBehaviour
{
    [Tooltip("Onde procurar os pinheiros")]
    public Transform searchRoot;
    [Tooltip("Prefixo do nome dos pinheiros")]
    public string treePrefix = "SM_PineTree";
    [Range(0, 1)] public float treeFraction = 0.4f;
    public int bulbsPerTree = 28;
    public float turns = 3.2f;
    [Tooltip("Faixa da altura do pinheiro coberta pelas luzes (0 = base, 1 = topo)")]
    public Vector2 heightRange = new Vector2(0.18f, 0.88f);
    [Tooltip("Raio da lâmpada (m)")]
    public float bulbSize = 0.16f;
    [Tooltip("Afasta as lâmpadas do tronco (1 = cone pelas bordas da árvore)")]
    public float radiusScale = 1.05f;
    public Color[] palette =
    {
        new Color(1f, 0.78f, 0.42f),
        new Color(1f, 0.5f, 0.2f),
        new Color(1f, 0.3f, 0.22f),
        new Color(1f, 0.92f, 0.65f),
    };
    public int seed = 7;
    [Tooltip("Pinheiros dentro destas áreas sempre recebem luzes (ex.: árvores do lago)")]
    public Bounds[] alwaysLitAreas = new Bounds[0];
    [Tooltip("Árvores informadas à mão (bounds em mundo), sempre acesas. Útil para árvores animadas: " +
             "coloque este componente como filho do osso para as luzes acompanharem.")]
    public Bounds[] manualTrees = new Bounds[0];
    [Tooltip("Marque para recalcular no Editor")]
    public bool rebuild;

    [SerializeField, HideInInspector] List<Vector3> positions = new List<Vector3>();
    [SerializeField, HideInInspector] List<Color> colors = new List<Color>();

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
        colors.Clear();
        var rngManual = new System.Random(seed + 5);
        foreach (var b in manualTrees) AddTree(b, rngManual);
        if (searchRoot != null)
        {
            var rng = new System.Random(seed);
            foreach (var r in searchRoot.GetComponentsInChildren<MeshRenderer>(true))
            {
                if (!r.name.StartsWith(treePrefix)) continue;
                var b = r.bounds;
                bool forced = false;
                foreach (var area in alwaysLitAreas) if (area.Contains(b.center)) forced = true;
                if (rng.NextDouble() > treeFraction && !forced) continue;
                AddTree(b, rng);
            }
        }
        BuildMesh();
        UnityEditor.EditorUtility.SetDirty(this);
    }

    void AddTree(Bounds b, System.Random rng)
    {
        float h = b.size.y;
        float baseR = Mathf.Min(b.size.x, b.size.z) * 0.5f;
        float phase = (float)rng.NextDouble() * Mathf.PI * 2f;
        for (int i = 0; i < bulbsPerTree; i++)
        {
            float t = (i + 0.5f) / bulbsPerTree;
            float hy = Mathf.Lerp(heightRange.x, heightRange.y, t);
            float rad = baseR * (1f - hy) * radiusScale;
            float ang = phase + t * turns * Mathf.PI * 2f;
            var p = new Vector3(b.center.x + Mathf.Cos(ang) * rad, b.min.y + hy * h, b.center.z + Mathf.Sin(ang) * rad);
            positions.Add(transform.InverseTransformPoint(p));
            colors.Add(palette[rng.Next(palette.Length)]);
        }
    }
#endif

    void BuildMesh()
    {
        if (mesh == null) mesh = new Mesh { name = "TreeLights", hideFlags = HideFlags.DontSave };
        mesh.Clear();
        int n = positions.Count;
        var v = new Vector3[n * 4];
        var uv0 = new Vector2[n * 4];
        var uv1 = new Vector2[n * 4];
        var col = new Color[n * 4];
        var tri = new int[n * 6];
        Vector2[] c = { new Vector2(-1, -1), new Vector2(1, -1), new Vector2(1, 1), new Vector2(-1, 1) };
        var rng = new System.Random(seed + 1);
        for (int i = 0; i < n; i++)
        {
            float ph = (float)rng.NextDouble();
            for (int k = 0; k < 4; k++)
            {
                v[i * 4 + k] = positions[i];
                uv0[i * 4 + k] = c[k];
                uv1[i * 4 + k] = new Vector2(bulbSize, ph);
                col[i * 4 + k] = i < colors.Count ? colors[i] : Color.white;
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
        var bb = mesh.bounds; bb.Expand(2f); mesh.bounds = bb;
        GetComponent<MeshFilter>().sharedMesh = mesh;
        var mr = GetComponent<MeshRenderer>();
        mr.shadowCastingMode = ShadowCastingMode.Off;
        mr.receiveShadows = false;
        mr.lightProbeUsage = LightProbeUsage.Off;
        mr.reflectionProbeUsage = ReflectionProbeUsage.Off;
    }
}
