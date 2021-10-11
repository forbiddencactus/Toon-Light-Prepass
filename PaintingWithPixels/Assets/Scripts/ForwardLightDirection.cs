using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ForwardLightDirection : MonoBehaviour
{
    public bool isStatic = true;
    public float rotateTime = 1.0f;
    private float currentRotateTime = 0.0f;
    private MaterialPropertyBlock propertyBlock;

    private Renderer objectRenderer;

    private LightComponent targetLightSource;
    private LightComponent newLightSourceTarget;
    private Vector3 targetDirection;
    private bool flippingDirection = false;

    public float defaultDistance = 3;
    private bool fetchedOriginalDirection = false;
    private Vector3 originalDirection = Vector3.zero;

    // Use start to delay this step from everything else which uses awake...
    private void Start() 
    {
        if(propertyBlock == null)
        {
           propertyBlock = new MaterialPropertyBlock();
        }

        objectRenderer = GetComponent<Renderer>();

        // If we're a static object, just sample the static lights for our forward direction at the start of the game... 
        if (isStatic)
        {
            LightComponent nearestLight = null;
            float distance = float.MaxValue;
            foreach(LightComponent light in LightComponent.staticLights)
            {
                float checkDistance = Vector3.Distance(light.transform.position,transform.position);

                if (nearestLight == null || checkDistance < distance)
                {
                    nearestLight = light;
                    distance = checkDistance;
                }
            }

            newLightSourceTarget = nearestLight;
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (!isStatic)
        {
            LightComponent nearestLight = null;
            float distance = float.MaxValue;
            foreach(LightComponent light in LightComponent.staticLights)
            {
                float checkDistance = Vector3.Distance(light.transform.position,transform.position);

                if (nearestLight == null || checkDistance < distance)
                {
                    nearestLight = light;
                    distance = checkDistance;
                }
            }

            newLightSourceTarget = nearestLight;
        }


        objectRenderer.GetPropertyBlock(propertyBlock);
        Vector3 currentLightDir = propertyBlock.GetVector("_globalDefaultLightDir");

        if(!fetchedOriginalDirection)
        {
            originalDirection = currentLightDir;
            fetchedOriginalDirection = true;
        }

        if(newLightSourceTarget != targetLightSource)
        {
            targetLightSource = newLightSourceTarget;
            flippingDirection = true;
        }

        targetDirection = -(targetLightSource.transform.position - transform.position).normalized;
        
        Vector3 finalDirection;
        if(flippingDirection)
        {
            currentRotateTime += Time.deltaTime;

            if(currentLightDir != targetDirection)
            {
                finalDirection = Vector3.Lerp(currentLightDir, targetDirection, currentRotateTime / rotateTime);
            }
            else
            {
                currentRotateTime = 0.0f;
                flippingDirection = false;
                finalDirection = targetDirection;
                //Debug.Log("Done Rotating!");
            }
        }
        else
        {
            finalDirection = targetDirection;
        }


        propertyBlock.Clear();
        propertyBlock.SetVector("_globalDefaultLightDir", finalDirection);
        propertyBlock.SetColor("_LightColour", targetLightSource.lightColour);
        objectRenderer.SetPropertyBlock(propertyBlock);
    }
}
