import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss'
})
export class AppComponent {
  title = 'hawkeye';

  ngOnInit() {
    const ws = new WebSocket('ws://localhost:5892');

    ws.onmessage = (event) => {
      const blob = new Blob([event.data], { type: 'image/jpeg' });
      const url = URL.createObjectURL(blob);
      const img = new Image();

      img.onload = () => {
        const canvas1 = document.getElementById('canvas1') as HTMLCanvasElement | null;
        const canvas2 = document.getElementById('canvas2') as HTMLCanvasElement | null;
        const canvas3 = document.getElementById('canvas3') as HTMLCanvasElement | null;
      
        if (canvas1 && canvas2 && canvas3) {
          canvas1.getContext('2d')?.drawImage(img, 0, 0, canvas1.width, canvas1.height);
          canvas2.getContext('2d')?.drawImage(img, 0, 0, canvas2.width, canvas2.height);
          canvas3.getContext('2d')?.drawImage(img, 0, 0, canvas3.width, canvas3.height);
        }
      
        URL.revokeObjectURL(url);
      };

      img.src = url;
    };

    ws.onerror = (error) => {
      const errorElement = document.getElementById('error');
      if (errorElement) {
        errorElement.textContent = 'WebSocket error: ' + error;
      }
    };
  }
}
