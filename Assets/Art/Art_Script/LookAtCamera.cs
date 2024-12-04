using UnityEngine;

public class LookAtCamera : MonoBehaviour
{
    private Transform cameraTransform; // Referência para a posição da câmera

    private void Start()
    {
        cameraTransform = Camera.main.transform; // Obtém a referência da câmera principal
    }

    private void Update()
    {
        transform.LookAt(cameraTransform); // Faz o objeto olhar sempre para a câmera
    }
}
