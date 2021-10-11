using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CharacterController))]
public class PigMove : MonoBehaviour
{
    public InputAction moveAction;

    public float moveSpeed = 2f;

    public bool InvertY = false;

    public bool InvertX = true;
    private CharacterController controller;
    private float gravity;
    private Animator animator;

    // Start is called before the first frame update
    void Awake()
    {
        controller = GetComponent<CharacterController>();
        animator = GetComponent<Animator>();
        moveAction.Enable();
    }

    // This is the most horrendous character controller ever, but hey, this isn't a talk on making good character movement. :>
    void Update()
    {
        Vector2 moveMovement = moveAction.ReadValue<Vector2>().normalized;
        moveMovement.y = InvertY ? -moveMovement.y : moveMovement.y;
        moveMovement.x = (InvertX ? -moveMovement.x : moveMovement.x);

        float finalX = moveMovement.x * moveSpeed * Time.deltaTime * 10;
        float finalY = Mathf.Clamp(moveMovement.y * moveSpeed * Time.deltaTime, 0, 100);

        gravity = 9.81f;

        if ( controller.isGrounded ) 
        {
            gravity = 0;
        }

        animator.SetFloat("animSpeed", finalY * 10);
        transform.eulerAngles = new Vector3(transform.eulerAngles.x, transform.eulerAngles.y + finalX, transform.eulerAngles.z);
        Vector3 moveDirection = transform.TransformDirection(Vector3.forward) * finalY; 
        moveDirection.y -= gravity * Time.deltaTime;
        controller.Move(moveDirection);

    }
}
