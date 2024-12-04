using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.Video;
using System.Collections;

public class VideoController : MonoBehaviour
{
    public VideoPlayer videoPlayer; // Arraste o VideoPlayer para esta vari�vel no Inspector.
    public GameObject videoObject;

    void Start()
    {
        if (videoPlayer == null)
        {
            Debug.LogError("VideoPlayer n�o atribu�do no Inspector!");
            return;
        }


    }

    /// <summary>
    /// Inicia o v�deo no VideoPlayer
    /// </summary>
    public void PlayVideo()
    {
        videoObject.SetActive(true);
        // Registra o evento para quando o v�deo terminar
        videoPlayer.loopPointReached += OnVideoEnd;
        if (videoPlayer != null)
        {
            videoPlayer.Play();
            Debug.Log("V�deo iniciado.");
        }
    }

    /// <summary>
    /// Chamado automaticamente quando o v�deo termina
    /// </summary>
    private void OnVideoEnd(VideoPlayer vp)
    {
        Debug.Log("V�deo terminou.");
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
