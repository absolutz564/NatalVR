using System;
using UnityEngine;

public class ControllerInputHandler : MonoBehaviour
{
    public Animator animator;  // Referência ao Animator

    public GameObject MessageToHide;

    private bool actionTriggered = false;  // Flag para garantir que a ação aconteça apenas uma vez
    string pressedKey;

    void Update()
    {
        // Verifica se qualquer tecla ou botão foi pressionado
        if (Input.anyKeyDown)
        {
            foreach (KeyCode key in Enum.GetValues(typeof(KeyCode)))
            {
                if (Input.GetKeyDown(key))
                {
                    Debug.Log("Tecla pressionada: " + key.ToString());
                    pressedKey = key.ToString();
                }
            }
            Debug.Log(pressedKey);

            // Verifica se a tecla pressionada é o Joystick1Button2
            if (!string.IsNullOrEmpty(pressedKey) && (pressedKey == "Joystick1Button2" || pressedKey == "Joystick2Button0"))
            {
                // Ação a ser realizada quando o Joystick1Button2 for pressionado
                Debug.Log("Joystick1Button2 pressionado!");

                // Aqui você pode disparar o trigger do Animator e alterar o pai do GameObject
                animator.SetTrigger("Init");

                MessageToHide.SetActive(false);
                // Opcionalmente, marcar a ação como já executada, se necessário
                actionTriggered = true;
            }
        }
    }


    // Função para resetar a flag e permitir que a ação seja disparada novamente
    public void ResetAction()
    {
        actionTriggered = false;
    }
}
