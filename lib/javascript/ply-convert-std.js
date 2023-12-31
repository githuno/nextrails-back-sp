const fs = require('fs');

class Worker {
  constructor() {
    this.buffer = null;
    this.vertexCount = 0;
    this.viewProj = null;
    this.sortRunning = false;
  }

  runSort(viewProj) {
    if (!this.buffer) return;

    const f_buffer = new Float32Array(this.buffer);
    const u_buffer = new Uint8Array(this.buffer);

    const depthList = new Float32Array(this.vertexCount);
    const depthIndex = new Uint32Array(this.vertexCount);
    for (let j = 0; j < this.vertexCount; j++) {
      depthList[j] =
        viewProj[2] * f_buffer[8 * j + 0] +
        viewProj[6] * f_buffer[8 * j + 1] +
        viewProj[10] * f_buffer[8 * j + 2];
      depthIndex[j] = j;
    }
    depthIndex.sort((a, b) => depthList[a] - depthList[b]);

    const quat = new Float32Array(4 * this.vertexCount);
    const scale = new Float32Array(3 * this.vertexCount);
    const center = new Float32Array(3 * this.vertexCount);
    const color = new Float32Array(4 * this.vertexCount);

    for (let j = 0; j < this.vertexCount; j++) {
      const i = depthIndex[j];

      quat[4 * j + 0] = (u_buffer[32 * i + 28 + 0] - 128) / 128;
      quat[4 * j + 1] = (u_buffer[32 * i + 28 + 1] - 128) / 128;
      quat[4 * j + 2] = (u_buffer[32 * i + 28 + 2] - 128) / 128;
      quat[4 * j + 3] = (u_buffer[32 * i + 28 + 3] - 128) / 128;

      center[3 * j + 0] = f_buffer[8 * i + 0];
      center[3 * j + 1] = f_buffer[8 * i + 1];
      center[3 * j + 2] = f_buffer[8 * i + 2];

      color[4 * j + 0] = u_buffer[32 * i + 24 + 0] / 255;
      color[4 * j + 1] = u_buffer[32 * i + 24 + 1] / 255;
      color[4 * j + 2] = u_buffer[32 * i + 24 + 2] / 255;
      color[4 * j + 3] = u_buffer[32 * i + 24 + 3] / 255;

      scale[3 * j + 0] = f_buffer[8 * i + 3 + 0];
      scale[3 * j + 1] = f_buffer[8 * i + 3 + 1];
      scale[3 * j + 2] = f_buffer[8 * i + 3 + 2];
    }

    this.postMessage({ quat, center, color, scale });
  }

  processPlyBuffer(inputBuffer) {
    const ubuf = new Uint8Array(inputBuffer);
    // 10KB ought to be enough for a header...
    const header = new TextDecoder().decode(ubuf.slice(0, 1024 * 10));
    const header_end = "end_header\n";
    const header_end_index = header.indexOf(header_end);
    if (header_end_index < 0)
        throw new Error("Unable to read .ply file header");
    const vertexCount = parseInt(/element vertex (\d+)\n/.exec(header)[1]);
    console.log("Vertex Count", vertexCount);
    let row_offset = 0,
        offsets = {},
        types = {};
    const TYPE_MAP = {
        double: "getFloat64",
        int: "getInt32",
        uint: "getUint32",
        float: "getFloat32",
        short: "getInt16",
        ushort: "getUint16",
        uchar: "getUint8",
    };
    for (let prop of header
        .slice(0, header_end_index)
        .split("\n")
        .filter((k) => k.startsWith("property "))) {
        const [p, type, name] = prop.split(" ");
        const arrayType = TYPE_MAP[type] || "getInt8";
        types[name] = arrayType;
        offsets[name] = row_offset;
        row_offset += parseInt(arrayType.replace(/[^\d]/g, "")) / 8;
    }
    console.log("Bytes per row", row_offset, types, offsets);

    let dataView = new DataView(
        inputBuffer,
        header_end_index + header_end.length,
    );
    let row = 0;
    const attrs = new Proxy(
        {},
        {
            get(target, prop) {
                if (!types[prop]) throw new Error(prop + " not found");
                return dataView[types[prop]](
                    row * row_offset + offsets[prop],
                    true,
                );
            },
        },
    );

    console.time("calculate importance");
    let sizeList = new Float32Array(vertexCount);
    let sizeIndex = new Uint32Array(vertexCount);
    for (row = 0; row < vertexCount; row++) {
        sizeIndex[row] = row;
        if (!types["scale_0"]) continue;
        const size =
            Math.exp(attrs.scale_0) *
            Math.exp(attrs.scale_1) *
            Math.exp(attrs.scale_2);
        const opacity = 1 / (1 + Math.exp(-attrs.opacity));
        sizeList[row] = size * opacity;
    }
    console.timeEnd("calculate importance");

    console.time("sort");
    sizeIndex.sort((b, a) => sizeList[a] - sizeList[b]);
    console.timeEnd("sort");

    // 6*4 + 4 + 4 = 8*4
    // XYZ - Position (Float32)
    // XYZ - Scale (Float32)
    // RGBA - colors (uint8)
    // IJKL - quaternion/rot (uint8)
    const rowLength = 3 * 4 + 3 * 4 + 4 + 4;
    const buffer = new ArrayBuffer(rowLength * vertexCount);

    console.time("build buffer");
    for (let j = 0; j < vertexCount; j++) {
        row = sizeIndex[j];

        const position = new Float32Array(buffer, j * rowLength, 3);
        const scales = new Float32Array(buffer, j * rowLength + 4 * 3, 3);
        const rgba = new Uint8ClampedArray(
            buffer,
            j * rowLength + 4 * 3 + 4 * 3,
            4,
        );
        const rot = new Uint8ClampedArray(
            buffer,
            j * rowLength + 4 * 3 + 4 * 3 + 4,
            4,
        );

        if (types["scale_0"]) {
            const qlen = Math.sqrt(
                attrs.rot_0 ** 2 +
                    attrs.rot_1 ** 2 +
                    attrs.rot_2 ** 2 +
                    attrs.rot_3 ** 2,
            );

            rot[0] = (attrs.rot_0 / qlen) * 128 + 128;
            rot[1] = (attrs.rot_1 / qlen) * 128 + 128;
            rot[2] = (attrs.rot_2 / qlen) * 128 + 128;
            rot[3] = (attrs.rot_3 / qlen) * 128 + 128;

            scales[0] = Math.exp(attrs.scale_0);
            scales[1] = Math.exp(attrs.scale_1);
            scales[2] = Math.exp(attrs.scale_2);
        } else {
            scales[0] = 0.01;
            scales[1] = 0.01;
            scales[2] = 0.01;

            rot[0] = 255;
            rot[1] = 0;
            rot[2] = 0;
            rot[3] = 0;
        }

        position[0] = attrs.x;
        position[1] = attrs.y;
        position[2] = attrs.z;

        if (types["f_dc_0"]) {
            const SH_C0 = 0.28209479177387814;
            rgba[0] = (0.5 + SH_C0 * attrs.f_dc_0) * 255;
            rgba[1] = (0.5 + SH_C0 * attrs.f_dc_1) * 255;
            rgba[2] = (0.5 + SH_C0 * attrs.f_dc_2) * 255;
        } else {
            rgba[0] = attrs.red;
            rgba[1] = attrs.green;
            rgba[2] = attrs.blue;
        }
        if (types["opacity"]) {
            rgba[3] = (1 / (1 + Math.exp(-attrs.opacity))) * 255;
        } else {
            rgba[3] = 255;
        }
    }
    console.timeEnd("build buffer");
    return buffer;
}

  postMessage(data) {
    return data;
  }

  onmessage(e) {
    if (e.data.ply) {
      this.vertexCount = 0;
      this.runSort(this.viewProj);
      this.buffer = this.processPlyBuffer(e.data.ply);
      this.vertexCount = Math.floor(this.buffer.byteLength / this.rowLength);
      this.postMessage({ buffer: this.buffer });
    } else if (e.data.buffer) {
      this.buffer = e.data.buffer;
      this.vertexCount = e.data.vertexCount;
    } else if (e.data.vertexCount) {
      this.vertexCount = e.data.vertexCount;
    } else if (e.data.view) {
      this.viewProj = e.data.view;
      this.throttledSort();
    }
  }
}

// Check if the script is being run directly
if (require.main === module) {
  // Get the input and output file names from the command line arguments
  const inputFileName = process.argv[2];
  const outputFileName = process.argv[3];

  // Determine the input stream
  const inputStream = inputFileName === '-'
    ? process.stdin
    : fs.createReadStream(inputFileName);

  // Determine the output stream
  const outputStream = outputFileName === '-'
    ? process.stdout
    : fs.createWriteStream(outputFileName);

  // Create a worker
  const worker = new Worker();

  // Read the input stream and convert it to an ArrayBuffer
  let inputBuffer = [];
  inputStream.on('data', chunk => {
    inputBuffer.push(chunk);
  });

  inputStream.on('end', () => {
    const arrayBuffer = Uint8Array.from(Buffer.concat(inputBuffer)).buffer;

    // Process the PLY buffer
    const outputBuffer = worker.processPlyBuffer(arrayBuffer);

    // Convert the ArrayBuffer to a Buffer
    const outputData = Buffer.from(outputBuffer);

    // Write the output to the output stream
    outputStream.write(outputData, () => {
      outputStream.end();
    });
  });
}
