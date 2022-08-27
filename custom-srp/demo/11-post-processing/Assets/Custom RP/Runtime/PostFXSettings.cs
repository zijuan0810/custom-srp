using UnityEngine;

[CreateAssetMenu(menuName = "Rendering/Custom Post FX Settings")]
public class PostFXSettings : ScriptableObject
{
    [SerializeField]
    private Shader _shader = default;

    [System.NonSerialized]
    private Material _material;
    
    [System.Serializable]
    public struct BloomSettings {
        [Range(0f, 16f)]
        public int maxIterations;
        [Min(1f)]
        public int downscaleLimit;
        public bool bicubicUpsampling;
        [Min(0f)]
        public float threshold;
        [Range(0f, 1f)]
        public float thresholdKnee;
    }
    
    [SerializeField]
    BloomSettings bloom = default;
    
    public BloomSettings Bloom => bloom;

    public Material Material
    {
        get
        {
            if (_material == null && _shader != null)
            {
                _material = new Material(_shader);
                _material.hideFlags = HideFlags.HideAndDontSave;
            }

            return _material;
        }
    }
}