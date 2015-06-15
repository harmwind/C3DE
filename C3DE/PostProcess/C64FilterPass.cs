﻿using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using System;

namespace C3DE.PostProcess
{
    public class C64FilterPass : PostProcessPass
    {
        public readonly float[][] C64Palette = new float[16][]
        {
            new float[3] { 0.0f, 0.0f, 0.0f },
	        new float[3] { 62.0f, 49.0f, 162.0f },
	        new float[3] { 87.0f, 66.0f, 0.0f },
	        new float[3] { 140.0f, 62.0f, 52.0f },
	        new float[3] { 84.0f, 84.0f, 84.0f },
	        new float[3] { 141.0f, 71.0f, 179.0f },
	        new float[3] { 144.0f, 95.0f, 37.0f },
	        new float[3] { 124.0f, 112.0f, 218.0f },
	        new float[3] { 128.0f, 128.0f, 129.0f },
	        new float[3] { 104.0f, 169.0f, 65.0f },
	        new float[3] { 187.0f, 119.0f, 109.0f },
	        new float[3] { 122.0f, 191.0f, 199.0f },
	        new float[3] { 171.0f, 171.0f, 171.0f },
	        new float[3] { 208.0f, 220.0f, 113.0f },
	        new float[3] { 172.0f, 234.0f, 136.0f },
	        new float[3] { 255.0f, 255.0f, 255.0f }
        };

        private Effect _c64filterEffect;
        private Vector3[] _palette;

        public void SetPalette(float[][] palette)
        {
            if (palette.Length != 16)
                throw new Exception("The palette must contains 16 colors");

            _palette = new Vector3[16];

            for (int i = 0; i < 16; i++)
                _palette[i] = new Vector3(palette[i][0], palette[i][1], palette[i][2]);

            if (_c64filterEffect != null)
                _c64filterEffect.Parameters["Palette"].SetValue(_palette);
        }

        public override void Initialize(ContentManager content)
        {
            _c64filterEffect = content.Load<Effect>("FX/PostProcess/C64Filter");

            if (_palette == null)
                SetPalette(C64Palette);
            else
                _c64filterEffect.Parameters["Palette"].SetValue(_palette);
        }

        public override void Apply(SpriteBatch spriteBatch, RenderTarget2D renderTarget)
        {
            spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, DepthStencilState.None, RasterizerState.CullNone, _c64filterEffect);
            spriteBatch.Draw(renderTarget, Vector2.Zero, Color.White);
            _c64filterEffect.Parameters["TargetTexture"].SetValue(renderTarget);
            _c64filterEffect.CurrentTechnique.Passes[0].Apply();
            spriteBatch.End();
        }
    }
}