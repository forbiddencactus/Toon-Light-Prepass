using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Firefly : MonoBehaviour
{
    // Start is called before the first frame update
    [SerializeField]
    private LightComponent lightChild;

    [SerializeField]
    private SpriteRenderer outerCentreSpriteRenderer;

    [SerializeField]
    private float speed = 2f;


    private void Awake() 
    {
        transform.eulerAngles = new Vector3(transform.eulerAngles.x, Random.Range(1, 359), transform.eulerAngles.z);
    }

    // Update is called once per frame
    void Update()
    {
        transform.Translate(Vector3.forward * Time.deltaTime * speed);

        // Sprite should always face the camera. 
        outerCentreSpriteRenderer.transform.LookAt(Camera.main.transform.position, -Vector3.up);

        // Set the colour of our firefly to match the colour of the light. 
        outerCentreSpriteRenderer.color = new Color(lightChild.lightColour.r,lightChild.lightColour.g,lightChild.lightColour.b, 1);
    }

    //Upon collision with another GameObject, this GameObject will reverse direction
    private void OnCollisionEnter(Collision collision)
    {
        // Change the direction a bit. 
        transform.eulerAngles = new Vector3(transform.eulerAngles.x, Random.Range(transform.eulerAngles.y + 10, transform.eulerAngles.y - 10), transform.eulerAngles.z);

        // Reverse direction.
        speed = speed * -1;
    }
}
