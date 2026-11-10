using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

// Desenha halos de luz (glow) em cima das partes emissivas do cenário: postes e janelas das casas.
// Todos os halos ficam num único mesh (1 draw call). As posições são calculadas no Editor e salvas na cena,
// porque em runtime o static batching junta as malhas e não dá mais para achar as partes emissivas.
// O halo de cada casa acompanha a janela: aparece quando o material da janela vira o emissivo.
[ExecuteAlways]
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class GlowHalos : MonoBehaviour
{
    [System.Serializable]
    public class HaloSource
    {
        [Tooltip("Material emissivo que indica onde colocar o halo")]
        public Material litMaterial;
        [Tooltip("Material de 'desligado' que pode ocupar o mesmo slot (ex.: janela apagada). Opcional.")]
        public Material offMaterial;
        public Color color = new Color(1f, 0.55f, 0.22f);
        [Tooltip("Raio do halo em metros")]
        public float size = 1.2f;
        [Tooltip("Sobe o halo em relação ao centro da parte emissiva")]
        public float heightOffset = 0f;
    }

    [System.Serializable]
    public class HaloPoint
    {
        public Renderer renderer;
        public int materialSlot;
        public int source;
        public Vector3 position;
    }

    public List<HaloSource> sources = new List<HaloSource>();
    [Tooltip("Objetos onde procurar as partes emissivas")]
    public List<Transform> searchRoots = new List<Transform>();
    [Tooltip("Marque para recalcular as posições no Editor")]
    public bool rebuild;

    [SerializeField, HideInInspector] List<HaloPoint> points = new List<HaloPoint>();

    Mesh mesh;
    Color[] colors;
    bool[] lit;
    float nextCheck;

    void OnEnable()
    {
#if UNITY_EDITOR
        if (!Application.isPlaying && points.Count == 0) CollectPoints();
#endif
        BuildMesh();
    }

    void OnDisable()
    {
        if (mesh != null)
        {
            if (Application.isPlaying) Destroy(mesh); else DestroyImmediate(mesh);
        }
    }

#if UNITY_EDITOR
    void OnValidate()
    {
        if (!rebuild) return;
        rebuild = false;
        UnityEditor.EditorApplication.delayCall += () =>
        {
            if (this == null) return;
            CollectPoints();
            BuildMesh();
            UnityEditor.EditorUtility.SetDirty(this);
        };
    }

    // Recalcula as posições dos halos (usado no Editor)
    public void Rebuild()
    {
        CollectPoints();
        BuildMesh();
        UnityEditor.EditorUtility.SetDirty(this);
    }

    void CollectPoints()
    {
        points.Clear();
        foreach (var root in searchRoots)
        {
            if (root == null) continue;
            foreach (var r in root.GetComponentsInChildren<MeshRenderer>(true))
            {
                var mf = r.GetComponent<MeshFilter>();
                if (mf == null || mf.sharedMesh == null) continue;
                var mats = r.sharedMaterials;
                for (int slot = 0; slot < mats.Length && slot < mf.sharedMesh.subMeshCount; slot++)
                {
                    int src = SourceIndex(mats[slot]);
                    if (src < 0) continue;
                    var b = mf.sharedMesh.GetSubMesh(slot).bounds;
                    var world = r.transform.TransformPoint(b.center) + Vector3.up * sources[src].heightOffset;
                    points.Add(new HaloPoint { renderer = r, materialSlot = slot, source = src, position = transform.InverseTransformPoint(world) });
                }
            }
        }
    }

    int SourceIndex(Material m)
    {
        if (m == null) return -1;
        for (int i = 0; i < sources.Count; i++)
            if (sources[i].litMaterial == m || (sources[i].offMaterial != null && sources[i].offMaterial == m)) return i;
        return -1;
    }
#endif

    void BuildMesh()
    {
        if (mesh == null)
        {
            mesh = new Mesh { name = "GlowHalos", hideFlags = HideFlags.DontSave };
            mesh.MarkDynamic();
        }
        mesh.Clear();

        int n = points.Count;
        var verts = new Vector3[n * 4];
        var corners = new Vector2[n * 4];
        var sizes = new Vector2[n * 4];
        colors = new Color[n * 4];
        lit = new bool[n];
        var tris = new int[n * 6];
        Vector2[] c = { new Vector2(-1, -1), new Vector2(1, -1), new Vector2(1, 1), new Vector2(-1, 1) };

        for (int i = 0; i < n; i++)
        {
            var p = points[i];
            var s = p.source < sources.Count ? sources[p.source] : null;
            lit[i] = IsLit(p);
            var col = s != null ? s.color : Color.white;
            col.a = lit[i] ? 1f : 0f;
            for (int k = 0; k < 4; k++)
            {
                verts[i * 4 + k] = p.position;
                corners[i * 4 + k] = c[k];
                sizes[i * 4 + k] = new Vector2(s != null ? s.size : 1f, 0);
                colors[i * 4 + k] = col;
            }
            tris[i * 6 + 0] = i * 4 + 0; tris[i * 6 + 1] = i * 4 + 1; tris[i * 6 + 2] = i * 4 + 2;
            tris[i * 6 + 3] = i * 4 + 0; tris[i * 6 + 4] = i * 4 + 2; tris[i * 6 + 5] = i * 4 + 3;
        }

        mesh.indexFormat = n * 4 > 65000 ? IndexFormat.UInt32 : IndexFormat.UInt16;
        mesh.vertices = verts;
        mesh.SetUVs(0, corners);
        mesh.SetUVs(1, sizes);
        mesh.colors = colors;
        mesh.triangles = tris;
        mesh.RecalculateBounds();
        var b = mesh.bounds;
        b.Expand(10f);
        mesh.bounds = b;
        GetComponent<MeshFilter>().sharedMesh = mesh;

        var mr = GetComponent<MeshRenderer>();
        mr.shadowCastingMode = ShadowCastingMode.Off;
        mr.receiveShadows = false;
        mr.lightProbeUsage = LightProbeUsage.Off;
        mr.reflectionProbeUsage = ReflectionProbeUsage.Off;
    }

    bool IsLit(HaloPoint p)
    {
        if (p.renderer == null || p.source >= sources.Count) return true;
        var s = sources[p.source];
        if (s.offMaterial == null) return true;
        var mats = p.renderer.sharedMaterials;
        return p.materialSlot < mats.Length && mats[p.materialSlot] == s.litMaterial;
    }

    // Verifica 4x por segundo se alguma janela acendeu/apagou (animação troca o material)
    void Update()
    {
        if (mesh == null || lit == null || Time.unscaledTime < nextCheck) return;
        nextCheck = Time.unscaledTime + 0.25f;
        bool changed = false;
        for (int i = 0; i < points.Count; i++)
        {
            bool now = IsLit(points[i]);
            if (now == lit[i]) continue;
            lit[i] = now;
            changed = true;
            for (int k = 0; k < 4; k++) colors[i * 4 + k].a = now ? 1f : 0f;
        }
        if (changed) mesh.colors = colors;
    }
}
