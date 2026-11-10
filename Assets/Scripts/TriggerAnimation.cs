using UnityEngine;

public class TriggerAnimation : MonoBehaviour
{
    public Animator targetAnimator; // Referência ao Animator do outro objeto
    public string parameterName = "event"; // Nome do parâmetro Trigger no Animator do outro objeto
    public GameObject objectToActivate; // Objeto que será ativado quando o player entrar no trigger

    [Header("Audio Settings")]
    public AudioSource audioSource; // Referência ao componente AudioSource
    public AudioClip soundClip; // Som que será tocado
    public GameObject objectToMove;  // O GameObject que terá seu pai alterado
    public GameObject newParent;  // O novo GameObject pai
    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player")) // Verifica se o objeto que entrou no trigger tem a tag "Player"
        {
            // Aciona o parâmetro Trigger para tocar a animação no outro objeto
            if (targetAnimator != null && !string.IsNullOrEmpty(parameterName))
            {
                targetAnimator.SetTrigger(parameterName);
            }

            // Ativa o objeto, se necessário
            if (objectToActivate != null)
            {
                objectToActivate.SetActive(true);
            }
        }
    }

    // Método chamado pelo evento de animação
    public void PlaySound()
    {
        if (audioSource != null && soundClip != null)
        {
            audioSource.PlayOneShot(soundClip);
        }
    }
    public void ChangeParent()
    {

        if (objectToMove != null && newParent != null)
        {
            objectToMove.transform.SetParent(newParent.transform);
        }

    }
}
