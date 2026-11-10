#if UNITY_EDITOR
using UnityEngine;
using UnityEngine.SceneManagement;

// Olhar com o mouse no Editor quando não há headset conectado.
// Segure o botão direito do mouse na janela Game e mova para girar a câmera.
// Se instala sozinho no OVRCameraRig da cena; não entra no build.
public class EditorMouseLook : MonoBehaviour
{
    public float sensitivity = 2f;
    public float maxPitch = 80f;

    private OVRCameraRig rig;
    private float yaw;
    private float pitch;

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    private static void Install()
    {
        SceneManager.sceneLoaded += (scene, mode) => AttachToRig();
        AttachToRig();
    }

    private static void AttachToRig()
    {
        if (OVRManager.isHmdPresent) return;

        OVRCameraRig found = FindAnyObjectByType<OVRCameraRig>();
        if (found != null && found.GetComponent<EditorMouseLook>() == null)
            found.gameObject.AddComponent<EditorMouseLook>();
    }

    private void OnEnable()
    {
        rig = GetComponent<OVRCameraRig>();
        rig.UpdatedAnchors += ApplyRotation;
    }

    private void OnDisable()
    {
        if (rig != null) rig.UpdatedAnchors -= ApplyRotation;
    }

    private void Update()
    {
        if (!Input.GetMouseButton(1)) return;

        yaw += Input.GetAxis("Mouse X") * sensitivity;
        pitch -= Input.GetAxis("Mouse Y") * sensitivity;
        pitch = Mathf.Clamp(pitch, -maxPitch, maxPitch);
    }

    // Sem headset o OVRManager não inicializa e o rig não dispara UpdatedAnchors,
    // então aplica aqui também.
    private void LateUpdate()
    {
        ApplyRotation(rig);
    }

    // Roda depois que o OVRCameraRig atualiza as âncoras, para não ser sobrescrito.
    private void ApplyRotation(OVRCameraRig r)
    {
        if (r == null || r.centerEyeAnchor == null) return;
        r.centerEyeAnchor.localRotation = Quaternion.Euler(pitch, yaw, 0f);
    }
}
#endif
