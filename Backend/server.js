import express from 'express' ;
import bodyParser from "body-parser";
import env from "dotenv";

env.config();

const app = express();
const PORT = process.env.PORT;


app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));


app.get("/", (req, res) => {
  res.send("backend running");
});


app.listen(PORT, () => {
  console.log(`Server started`);
});
