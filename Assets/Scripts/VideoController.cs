using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.Video;
using System.Collections;

public class VideoController : MonoBehaviour
{
    public VideoPlayer videoPlayer; // Arraste o VideoPlayer para esta variável no Inspector.
    public GameObject videoObject;

    void Start()
    {
        if (videoPlayer == null)
        {
            Debug.LogError("VideoPlayer não atribuído no Inspector!");
            return;
        }


    }

    /// <summary>
    /// Inicia o vídeo no VideoPlayer
    /// </summary>
    public void PlayVideo()
    {
        videoObject.SetActive(true);
        // Registra o evento para quando o vídeo terminar
        videoPlayer.loopPointReached += OnVideoEnd;
        if (videoPlayer != null)
        {
            videoPlayer.Play();
            Debug.Log("Vídeo iniciado.");
        }
    }

    /// <summary>
    /// Chamado automaticamente quando o vídeo termina
    /// </summary>
    private void OnVideoEnd(VideoPlayer vp)
    {
        Debug.Log("Vídeo terminou.");
        StartCoroutine(ReloadSceneAfterDelay(2f));
    }

    /// <summary>
    /// Aguarda um tempo antes de recarregar a cena
    /// </summary>
    private IEnumerator ReloadSceneAfterDelay(float delay)
    {
        yield return new WaitForSeconds(delay);
        Debug.Log("Recarregando cena...");
        SceneManager.LoadScene(SceneManager.GetActiveScene().name);
    }
}
