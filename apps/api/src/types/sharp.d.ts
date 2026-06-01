declare module 'sharp' {
  interface SharpPipeline {
    rotate(): SharpPipeline;
    resize(options: unknown): SharpPipeline;
    jpeg(options: unknown): SharpPipeline;
    toBuffer(): Promise<Buffer>;
  }

  export default function sharp(input: Buffer): SharpPipeline;
}
