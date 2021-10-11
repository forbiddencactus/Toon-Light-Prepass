using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightComponent : MonoBehaviour
{
    public static List<LightComponent> dynamicLights = new List<LightComponent>();
    public static List<LightComponent> staticLights = new List<LightComponent>();

    public bool isStatic = true;
    public Color lightColour;
    private MaterialPropertyBlock propertyBlock;
    private Renderer lightRenderer;
    private Transform theTransform;
    private Vector3 initialScale;
    private SphereCollider sphereCollider;

    private float animTime = 0;
    // Start is called before the first frame update
    void Awake()
    {
        if(propertyBlock == null)
        {
           propertyBlock = new MaterialPropertyBlock();
        }

        lightRenderer = GetComponent<Renderer>();
        initialScale = transform.localScale;
        sphereCollider = GetComponent<SphereCollider>();

        if(isStatic)
        {
            staticLights.Add(this);
        }
        else
        {
            dynamicLights.Add(this);
        }
    }

    // Update is called once per frame
    void Update()
    {
        // Try to do a smooth little pulsing thing. 
        animTime += Time.deltaTime;
        float transformScale = 1 +  Mathf.SmoothStep(0, 0.1f, Mathf.PingPong(animTime/10, 1));
        transform.localScale =  initialScale * transformScale;

        // Set the properties of our light volume. 
        // Note: we can't rely on the renderer to give us accurate data about the size of the dang sphere, so we'll use the collider instead! *upside down face*
        lightRenderer.GetPropertyBlock(propertyBlock);
        propertyBlock.Clear();
        propertyBlock.SetColor("_LightColour", lightColour);
        propertyBlock.SetVector("_LightOrigin", transform.position);//lightRenderer.bounds.center);
        propertyBlock.SetFloat("_LightDistance", sphereCollider.bounds.extents.x);//lightRenderer.bounds.extents.x);

        lightRenderer.SetPropertyBlock(propertyBlock);
    }
}
