import express from "express";
import cors from "cors";
import { corsOptions } from "./config/cors";
import { env } from "./config/env";
import { apiRouter } from "./routes";
import { localStorageRouter } from "./routes/localStorage.routes";
import { errorHandler } from "./middleware/errorHandler";

export function createApp() {
  const app = express();

  app.use(cors(corsOptions));
  app.use(express.json());

  if (env.STORAGE_PROVIDER === "local") {
    app.use(localStorageRouter);
  }

  app.use(apiRouter);
  app.use(errorHandler);

  return app;
}
