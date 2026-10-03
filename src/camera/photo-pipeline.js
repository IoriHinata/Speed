/** Browser/Android-facing port. A native camera adapter can provide a high-quality Blob. */
export class PhotoCaptureService {
  async toDataUrl(file) { if (!file?.type?.startsWith('image/')) throw new Error('Выберите изображение автомобиля'); return URL.createObjectURL(file); }
}
