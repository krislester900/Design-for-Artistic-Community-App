import { useState, useRef, useEffect, useCallback } from "react";
import { Mic, Square, X, Send, Pause, Play } from "lucide-react";

type VoiceRecorderProps = {
  onSendVoice: (audioBlob: Blob, duration: number) => void;
  onCancel: () => void;
};

export function VoiceRecorder({ onSendVoice, onCancel }: VoiceRecorderProps) {
  const [isRecording, setIsRecording] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [duration, setDuration] = useState(0);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [waveformData, setWaveformData] = useState<number[]>([]);

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animationRef = useRef<number | null>(null);
  const streamRef = useRef<MediaStream | null>(null);

  const formatDuration = useCallback((seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, "0")}`;
  }, []);

  const startRecording = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;

      const audioContext = new AudioContext();
      const source = audioContext.createMediaStreamSource(stream);
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 64;
      source.connect(analyser);
      analyserRef.current = analyser;

      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: MediaRecorder.isTypeSupported("audio/webm;codecs=opus")
          ? "audio/webm;codecs=opus"
          : "audio/webm",
      });

      mediaRecorderRef.current = mediaRecorder;
      chunksRef.current = [];

      mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };

      mediaRecorder.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: "audio/webm" });
        setAudioUrl(URL.createObjectURL(blob));
        stream.getTracks().forEach((t) => t.stop());
      };

      mediaRecorder.start(100);
      setIsRecording(true);
      setDuration(0);

      timerRef.current = setInterval(() => {
        setDuration((prev) => prev + 1);
      }, 1000);

      // Waveform animation
      const updateWaveform = () => {
        if (!analyserRef.current) return;
        const dataArray = new Uint8Array(analyserRef.current.frequencyBinCount);
        analyserRef.current.getByteFrequencyData(dataArray);
        const normalized = Array.from(dataArray).map((v) => v / 255);
        setWaveformData(normalized);
        animationRef.current = requestAnimationFrame(updateWaveform);
      };
      updateWaveform();
    } catch {
      onCancel();
    }
  }, [onCancel]);

  const stopRecording = useCallback(() => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== "inactive") {
      mediaRecorderRef.current.stop();
    }
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (animationRef.current) {
      cancelAnimationFrame(animationRef.current);
      animationRef.current = null;
    }
    setIsRecording(false);
    setIsPaused(false);
  }, []);

  const pauseRecording = useCallback(() => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state === "recording") {
      mediaRecorderRef.current.pause();
      setIsPaused(true);
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
    }
  }, []);

  const resumeRecording = useCallback(() => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state === "paused") {
      mediaRecorderRef.current.resume();
      setIsPaused(false);
      timerRef.current = setInterval(() => {
        setDuration((prev) => prev + 1);
      }, 1000);
    }
  }, []);

  const handleSend = useCallback(() => {
    stopRecording();
    if (chunksRef.current.length > 0) {
      const blob = new Blob(chunksRef.current, { type: "audio/webm" });
      onSendVoice(blob, duration);
    }
  }, [stopRecording, onSendVoice, duration]);

  const handleCancel = useCallback(() => {
    stopRecording();
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop());
    }
    onCancel();
  }, [stopRecording, onCancel]);

  useEffect(() => {
    if (!isRecording && !audioUrl) {
      startRecording();
    }
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      if (animationRef.current) cancelAnimationFrame(animationRef.current);
      if (streamRef.current) {
        streamRef.current.getTracks().forEach((t) => t.stop());
      }
    };
  }, []);

  return (
    <div className="flex items-center gap-3 rounded-2xl border border-primary/20 bg-primary/5 px-4 py-3">
      {/* Record/Pause/Resume button */}
      {!audioUrl ? (
        <>
          <button
            onClick={isRecording ? (isPaused ? resumeRecording : pauseRecording) : startRecording}
            className={`flex h-10 w-10 items-center justify-center rounded-full transition-all ${
              isRecording
                ? "bg-red-500 text-white shadow-lg shadow-red-500/30 animate-pulse"
                : "bg-primary text-primary-foreground"
            }`}
          >
            {isRecording ? (
              isPaused ? (
                <Play className="h-4 w-4" />
              ) : (
                <Pause className="h-4 w-4" />
              )
            ) : (
              <Mic className="h-4 w-4" />
            )}
          </button>

          {/* Waveform visualization */}
          <div className="flex flex-1 items-center gap-1 h-8">
            {isRecording && waveformData.length > 0 ? (
              <div className="flex items-center gap-0.5 h-full w-full">
                {waveformData.slice(0, 32).map((value, i) => (
                  <div
                    key={i}
                    className="flex-1 bg-primary/60 rounded-full transition-all duration-75"
                    style={{
                      height: `${Math.max(4, value * 32)}px`,
                    }}
                  />
                ))}
              </div>
            ) : (
              <div className="flex items-center gap-0.5 h-full w-full">
                {Array.from({ length: 32 }).map((_, i) => (
                  <div
                    key={i}
                    className="flex-1 h-1 bg-muted rounded-full"
                  />
                ))}
              </div>
            )}
          </div>

          {/* Duration */}
          <span className="text-xs font-mono text-muted-foreground min-w-[40px] text-right">
            {formatDuration(duration)}
          </span>
        </>
      ) : (
        <>
          {/* Playback preview */}
          <audio src={audioUrl} controls className="flex-1 h-8" />
        </>
      )}

      {/* Actions */}
      <div className="flex items-center gap-1">
        <button
          onClick={handleCancel}
          className="flex h-8 w-8 items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive"
          title="Annuler"
        >
          <X className="h-4 w-4" />
        </button>

        {audioUrl || (!isRecording && duration > 0) ? (
          <button
            onClick={handleSend}
            className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground transition-opacity hover:opacity-90"
            title="Envoyer"
          >
            <Send className="h-3.5 w-3.5" />
          </button>
        ) : isRecording && !isPaused ? (
          <button
            onClick={stopRecording}
            className="flex h-8 w-8 items-center justify-center rounded-full bg-red-500 text-white transition-opacity hover:opacity-90"
            title="Arrêter"
          >
            <Square className="h-3.5 w-3.5" />
          </button>
        ) : null}
      </div>
    </div>
  );
}